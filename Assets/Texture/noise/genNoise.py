###
#Author: mall1 mlldezh@gamil.com
#Date: 2024-07-27 19:14:02
#LastEditors: mall1 mlldezh@gamil.com
#LastEditTime: 2024-07-27 19:14:14
#FilePath: \LearnURPc:\Users\mall\workspace\noise\genNoise.py
#Description: 
#Copyright (c) 2024 by mlldezh@gamil.com, All Rights Reserved.
###
import numpy as np
from PIL import Image

def generate_rgba_noise_texture(width, height):
    # Create an array of random values for each channel (RGBA)
    noise = np.random.randint(0, 256, (height, width, 4), dtype=np.uint8)
    
    # Convert the array to an image
    img = Image.fromarray(noise, 'RGBA')
    
    return img

# Define the width and height of the texture
width, height = 256, 256

# Generate the noise texture
noise_texture = generate_rgba_noise_texture(width, height)

# Save the texture as an image file
noise_texture.save('rgba_noise_texture.png')
