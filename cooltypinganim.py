import time
import sys

whattotype = "c# is better tjan this lang"
typingspeed = 0.1 
# randomizespeed = false
indicator = "|"  

for char in whattotype:
    sys.stdout.write(char)
    sys.stdout.flush()
    time.sleep(typingspeed)
    sys.stdout.write(indicator)
    sys.stdout.flush()
    time.sleep(typingspeed / 2)
    sys.stdout.write("\b \b")
    sys.stdout.flush()

while True:
    sys.stdout.write(indicator)
    sys.stdout.flush()
    time.sleep(0.5)
    sys.stdout.write("\b \b")
    sys.stdout.flush()
    time.sleep(0.5)
