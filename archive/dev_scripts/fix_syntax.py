# Fix the syntax error by adding except/finally block
import sys
sys.path.insert(0, '.')

with open('aisri_safety_gate.py', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find the line with the return statement in get_safety_summary that needs except block
found_return = False
for i, line in enumerate(lines):
    if "'updated_at': datetime.now().isoformat()" in line:
        # Next line should be the closing }
        # After that we need except block before the new method
        for j in range(i+1, i+5):
            if '}' in lines[j]:
                # Insert except block after this
                except_block = """
        except Exception as e:
            return {
                'status': 'ERROR',
                'message': f'Error fetching safety summary: {str(e)}',
                'aisri_score': 0,
                'injury_risk': 50,
                'recovery_score': 50,
                'updated_at': datetime.now().isoformat()
            }
"""
                lines.insert(j+1, except_block)
                print(f'Added except block at line {j+1}')
                found_return = True
                break
        if found_return:
            break

if not found_return:
    print('Could not find insertion point')
    sys.exit(1)

with open('aisri_safety_gate.py', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print('Fixed syntax error')
