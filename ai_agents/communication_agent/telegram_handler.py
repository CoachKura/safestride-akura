"""
AISRi Communication Agent - Telegram Handler
Handles Telegram bot commands and message processing
"""
import os
import logging
from typing import Optional, Dict, Any
from telegram import Update, Bot
from telegram.ext import Application, CommandHandler, MessageHandler, filters, ContextTypes

logger = logging.getLogger(__name__)


class TelegramHandler:
    def __init__(self, supabase_handler, api_handler):
        self.token = os.getenv("TELEGRAM_TOKEN")
        if not self.token:
            raise ValueError("TELEGRAM_TOKEN must be set")
        
        self.supabase = supabase_handler
        self.api_handler = api_handler
        self.bot = Bot(token=self.token)
        self.application = None
        
        logger.info("✅ Telegram Handler initialized")

    async def start_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /start command"""
        user = update.effective_user
        telegram_id = str(user.id)
        
        # Check if athlete exists
        athlete = await self.supabase.get_athlete_by_telegram(telegram_id)
        
        if not athlete:
            # Create new athlete
            athlete = await self.supabase.create_athlete(
                telegram_id=telegram_id,
                first_name=user.first_name,
                username=user.username
            )
            
            message = f"""👋 Welcome to AISRi Coach, {user.first_name}!

I'm your AI-powered running coach. I can help you with:

🏃 Training recommendations
🩺 Injury risk assessment
📊 Performance predictions
📅 Weekly training plans

**Commands:**
/help - Show this help message
/today - Today's workout recommendation
/week - Weekly training plan
/stats - Your current stats

Just message me naturally about training, pain, or performance!
"""
        else:
            message = f"""👋 Welcome back, {user.first_name}!

Your AISRi Score: **{athlete.get('aisri_score', 50)}**
Training Status: **{athlete.get('training_status', 'ACTIVE')}**

How can I help you today?
"""
        
        await update.message.reply_text(message)

    async def help_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /help command"""
        message = """🤖 **AISRi Coach Help**

**Commands:**
/start - Start or restart conversation
/help - Show this help message
/today - Get today's workout recommendation
/week - Get weekly training plan
/stats - View your current stats

**Natural Language:**
Just message me! I understand:
• "I have knee pain" → Injury assessment
• "What should I train today?" → Daily recommendation
• "Can I run a 5K under 20 min?" → Performance prediction
• "Give me a training plan" → Weekly plan

💡 I work in group chats too! Just mention me or reply to my messages.
"""
        await update.message.reply_text(message, parse_mode="Markdown")

    async def today_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /today command"""
        user = update.effective_user
        telegram_id = str(user.id)
        
        athlete = await self.supabase.get_athlete_by_telegram(telegram_id)
        
        if not athlete:
            await update.message.reply_text("Please use /start first to register!")
            return
        
        # Call autonomous decision agent
        response = await self.api_handler.call_autonomous_decision(athlete)
        
        if response:
            # Update athlete metrics
            await self.supabase.update_athlete_metrics(
                athlete["id"],
                aisri_score=response.get("aisri_score"),
                injury_risk=response.get("injury_risk"),
                training_status=response.get("training_status")
            )
            
            message = self.api_handler.format_response(response, athlete)
            await update.message.reply_text(message, parse_mode="Markdown")
        else:
            await update.message.reply_text("Sorry, I couldn't generate a recommendation. Please try again.")

    async def week_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /week command"""
        user = update.effective_user
        telegram_id = str(user.id)
        
        athlete = await self.supabase.get_athlete_by_telegram(telegram_id)
        
        if not athlete:
            await update.message.reply_text("Please use /start first to register!")
            return
        
        # Call training plan agent
        response = await self.api_handler.generate_training_plan(athlete)
        
        if response:
            message = self.api_handler.format_response(response, athlete)
            await update.message.reply_text(message, parse_mode="Markdown")
        else:
            await update.message.reply_text("Sorry, I couldn't generate a training plan. Please try again.")

    async def stats_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /stats command"""
        user = update.effective_user
        telegram_id = str(user.id)
        
        athlete = await self.supabase.get_athlete_by_telegram(telegram_id)
        
        if not athlete:
            await update.message.reply_text("Please use /start first to register!")
            return
        
        message = f"""📊 **Your AISRi Stats**

👤 Name: {athlete.get('first_name', 'Unknown')}
🆔 Athlete ID: {athlete.get('id', 'N/A')[:8]}...

📈 AISRi Score: **{athlete.get('aisri_score', 50)}**
🩺 Injury Risk: **{athlete.get('injury_risk', 'UNKNOWN')}**
🏃 Training Status: **{athlete.get('training_status', 'ACTIVE')}**

Last Updated: {athlete.get('updated_at', 'Never')[:10]}
"""
        await update.message.reply_text(message, parse_mode="Markdown")

    async def handle_message(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle free-text messages with intelligent routing"""
        user = update.effective_user
        telegram_id = str(user.id)
        message_text = update.message.text
        
        # Get or create athlete
        athlete = await self.supabase.get_athlete_by_telegram(telegram_id)
        
        if not athlete:
            athlete = await self.supabase.create_athlete(
                telegram_id=telegram_id,
                first_name=user.first_name,
                username=user.username
            )
        
        # Route query to appropriate agent
        response = await self.api_handler.route_query(message_text, athlete)
        
        if response:
            # Update athlete metrics
            await self.supabase.update_athlete_metrics(
                athlete["id"],
                aisri_score=response.get("aisri_score"),
                injury_risk=response.get("injury_risk"),
                training_status=response.get("training_status")
            )
            
            # Log interaction
            formatted_message = self.api_handler.format_response(response, athlete)
            await self.supabase.log_interaction(
                athlete["id"],
                "telegram",
                "free_text",
                message_text,
                formatted_message
            )
            
            await update.message.reply_text(formatted_message, parse_mode="Markdown")
        else:
            await update.message.reply_text("Sorry, I couldn't process your request. Please try again or use /help.")

    async def send_daily_message(self, telegram_id: str, message: str):
        """Send daily automated message to athlete"""
        try:
            await self.bot.send_message(
                chat_id=telegram_id,
                text=message,
                parse_mode="Markdown"
            )
            logger.info(f"✅ Sent daily message to Telegram ID: {telegram_id}")
            return True
        except Exception as e:
            logger.error(f"❌ Failed to send daily message to {telegram_id}: {e}")
            return False

    def setup_handlers(self):
        """Setup command and message handlers"""
        self.application = Application.builder().token(self.token).build()
        
        # Command handlers
        self.application.add_handler(CommandHandler("start", self.start_command))
        self.application.add_handler(CommandHandler("help", self.help_command))
        self.application.add_handler(CommandHandler("today", self.today_command))
        self.application.add_handler(CommandHandler("week", self.week_command))
        self.application.add_handler(CommandHandler("stats", self.stats_command))
        
        # Message handler for free text
        self.application.add_handler(
            MessageHandler(filters.TEXT & ~filters.COMMAND, self.handle_message)
        )
        
        logger.info("✅ Telegram handlers configured")

    async def start_polling(self):
        """Start Telegram bot polling"""
        if not self.application:
            self.setup_handlers()
        
        await self.application.initialize()
        await self.application.start()
        await self.application.updater.start_polling()
        logger.info("✅ Telegram bot polling started")

    async def stop_polling(self):
        """Stop Telegram bot polling"""
        if self.application:
            await self.application.updater.stop()
            await self.application.stop()
            await self.application.shutdown()
            logger.info("✅ Telegram bot polling stopped")
