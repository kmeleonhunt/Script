# Hello dear user :) I recently been challenged to make a security solution without a router
# Making home security a thing without IP camera is a thing apparently but I somehow managed to do something interesting
# Note that this is my very first Python script and I will explain below how it work
# 
# Hardware Raspi 3B and IR Camera (ext HDD also couldn't afford the pricey micro SD cards :p)
#
# The script : It make several one hour length video and store it to an external or directly on a raspberry pi
#
# If you want the script to run in a loop I'm using a workaround as I haven't find a way to replace the first file in Range
# Workaround : I've made a simple reboot.sh script and use crontable to make them both run :
#
# sudo crontable -e | @reboot sleep 20 /home/pi/Desktop/myscript.py
#                     @daily /home/pi/Desktop/reboot.sh
# That the thoughts, that way every day when it reboot it simply relaunch the python script with no end
# If anyone have a cleaner solution to replace file without the reboot thingy reach me out.
# I'll try to keep my script updated as I work on them


import picamera
import time
from datetime import datetime

date = datetime.now().strftime("%d-%m-%Y_%I-%M-%S_%p")
path = "Your path"

while True:
	Camera = picamera.Picamera(resolution=(680, 480))
	for filename in camera.record_sequence(
		(path) + (date) + "%d.h264" % i for i in range(1, 49)):
		camera.wait_recording(3600)
