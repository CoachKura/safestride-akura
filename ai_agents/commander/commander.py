import os
from dataclasses import dataclass
from typing import Any

from dotenv import load_dotenv


_HERE = os.path.dirname(os.path.abspath(__file__))
load_dotenv(dotenv_path=os.path.join(_HERE, "..", ".env"), override=False)
load_dotenv(dotenv_path=os.path.join(_HERE, "..", "..", ".env"), override=False)


@dataclass(frozen=True)
class CommanderResult:
    ok: bool
    output: str
    meta: dict[str, Any]


def _require_env(name: str) -> str:
    value = os.getenv(name)
    if not value:
        raise RuntimeError(f"Missing required environment variable: {name}")
    return value


def _get_supabase_client():
    """Create a Supabase client from environment variables.

    Prefers `SUPABASE_SERVICE_KEY` when present, otherwise falls back to `SUPABASE_ANON_KEY`.
    """

    supabase_url = _require_env("SUPABASE_URL")
    supabase_key = (
        os.getenv("SUPABASE_SERVICE_KEY")
        or os.getenv("SUPABASE_SERVICE_ROLE_KEY")
        or os.getenv("SUPABASE_ANON_KEY")
    )
    if not supabase_key:
        raise RuntimeError(
            "Missing required environment variable: SUPABASE_SERVICE_KEY (preferred) or SUPABASE_ANON_KEY"
        )

    from supabase import create_client

    return create_client(supabase_url, supabase_key)


class AISRiCommander:
    """Thin convenience wrapper around Supabase queries used by AISRi."""

    def __init__(self):
        self._supabase = _get_supabase_client()

    def get_all_athletes(self):
        response = self._supabase.table("profiles").select("id, full_name").execute()
        return response.data

    def get_latest_aisri(self, athlete_id: str):
        """Fetch the latest AISRI assessment row for a user.

        The repo contains multiple schema variants in docs/migrations. In practice, we've
        seen environments where the FK is `profile_id` and others where it is `athlete_id`.
        Likewise, ordering may be by `assessment_date` or `created_at`.
        """

        filter_candidates = ["profile_id", "athlete_id", "user_id"]
        order_candidates = ["assessment_date", "created_at"]

        last_exc: Exception | None = None
        for filter_col in filter_candidates:
            for order_col in order_candidates:
                try:
                    response = (
                        self._supabase.table("AISRI_assessments")
                        .select("*")
                        .eq(filter_col, athlete_id)
                        .order(order_col, desc=True)
                        .limit(1)
                        .execute()
                    )
                    return response.data
                except Exception as exc:
                    # Common failures here are missing columns (e.g. 42703) or missing table.
                    # We try the next candidate combination before giving up.
                    last_exc = exc

        if last_exc is not None:
            raise last_exc
        return []


def kickoff(goal: str) -> CommanderResult:
    """Run a minimal CrewAI workflow.

    This is intentionally small: one agent, one task.
    You can expand this into a multi-agent crew or a LangGraph graph later.
    """

    if not goal or not goal.strip():
        return CommanderResult(ok=False, output="Goal is empty", meta={})

    # CrewAI typically relies on the OpenAI key via environment.
    # Keeping this explicit makes errors clearer.
    _require_env("OPENAI_API_KEY")

    try:
        from crewai import Agent, Crew, Process, Task
    except Exception as exc:  # pragma: no cover
        return CommanderResult(
            ok=False,
            output=f"CrewAI import failed: {exc}",
            meta={"hint": "Run: python -m pip install crewai"},
        )

    model = os.getenv("OPENAI_MODEL") or "gpt-4o-mini"

    commander = Agent(
        role="Commander",
        goal="Coordinate sub-agents to complete the requested objective.",
        backstory=(
            "You are the AISRi Commander agent. You break work into steps, assign it to "
            "specialists, and return a crisp final result."
        ),
        allow_delegation=False,
        verbose=True,
        llm=model,
    )

    task = Task(
        description=(
            "Given the user's goal, respond with: (1) a short plan (max 5 bullets), "
            "(2) the single next concrete action to take in this repo, and "
            "(3) any missing info required (max 3 questions).\n\n"
            f"USER GOAL: {goal}"
        ),
        expected_output="Plan + next action + questions",
        agent=commander,
    )

    crew = Crew(
        agents=[commander],
        tasks=[task],
        process=Process.sequential,
        verbose=True,
    )

    try:
        output = crew.kickoff()
    except Exception as exc:
        return CommanderResult(ok=False, output=f"Crew kickoff failed: {exc}", meta={})

    return CommanderResult(ok=True, output=str(output), meta={"model": model})


def main() -> None:
    import argparse

    parser = argparse.ArgumentParser(description="AISRi Commander")
    parser.add_argument(
        "--list-athletes",
        action="store_true",
        help="List athletes from Supabase (profiles.id, profiles.full_name)",
    )
    parser.add_argument(
        "--latest-aisri",
        metavar="PROFILE_ID",
        help='Fetch latest row from "AISRI_assessments" for the given profile id',
    )
    parser.add_argument("goal", nargs="*", help="Goal to execute")
    args = parser.parse_args()

    if args.list_athletes:
        commander = AISRiCommander()
        print(commander.get_all_athletes())
        return

    if args.latest_aisri:
        commander = AISRiCommander()
        print(commander.get_latest_aisri(args.latest_aisri))
        return

    goal = " ".join(args.goal).strip()
    if not goal:
        goal = "Generate a plan to connect Flutter -> FastAPI -> Supabase."

    result = kickoff(goal)
    if not result.ok:
        raise SystemExit(result.output)

    print(result.output)


if __name__ == "__main__":
    main()
