import mediapipe as mp
import cv2
import numpy as np
import time
import random

mp_drawing = mp.solutions.drawing_utils
mp_hands = mp.solutions.hands
score = 0

x_enemy = random.randint(50, 600)
y_enemy = random.randint(50, 400)

snake = []
snake_length = 1
snake_colors = [(204, 204, 255), (255, 204, 204)]

# Ukuran umpan dan obstacle
umpan_radius = 15
obstacle_width = 30
obstacle_height = 30
x_obstacle = random.randint(50, 600)
y_obstacle = random.randint(50, 400)

game_over_time = None  # Variabel untuk menyimpan waktu game over

def enemy(image):
    global score, x_enemy, y_enemy
    balonenemy = cv2.imread('balon.png')
    balonenemy = cv2.resize(balonenemy, (umpan_radius * 2, umpan_radius * 2))  # Resize image
    image[y_enemy:y_enemy+umpan_radius*2, x_enemy:x_enemy+umpan_radius*2] = balonenemy

def obstacle(image):
    global x_obstacle, y_obstacle
    cv2.rectangle(image, (x_obstacle, y_obstacle), (x_obstacle + obstacle_width, y_obstacle + obstacle_height), (0, 0, 255), -1)

def draw_snake(image):
    global snake
    for i, segment in enumerate(snake):
        color = snake_colors[i % len(snake_colors)]  # Mengambil warna berdasarkan indeks
        cv2.circle(image, (segment[0], segment[1]), 10, color, -1)

def move_snake(x, y):
    global snake, snake_length
    snake.append([x, y])
    if len(snake) > snake_length:
        del snake[0]

video = cv2.VideoCapture(0)

with mp_hands.Hands(min_detection_confidence=0.8, min_tracking_confidence=0.5) as hands:
    while video.isOpened():
        _, frame = video.read()

        image = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        image = cv2.flip(image, 1)
        imageHeight, imageWidth, _ = image.shape

        results = hands.process(image)

        image = cv2.cvtColor(image, cv2.COLOR_RGB2BGR)

        font = cv2.FONT_HERSHEY_SIMPLEX
        color = (255, 0, 255)
        text = cv2.putText(image, "Score: " + str(score), (480, 30), font, 1, color, 4, cv2.LINE_AA)

        enemy(image)
        obstacle(image)

        if results.multi_hand_landmarks:
            for num, hand in enumerate(results.multi_hand_landmarks):
                mp_drawing.draw_landmarks(image, hand, mp_hands.HAND_CONNECTIONS,
                                          mp_drawing.DrawingSpec(color=(250, 44, 250), thickness=2,
                                                                 circle_radius=2))

                # Mengambil koordinat ujung jari telunjuk
                index_fingertip = hand.landmark[mp_hands.HandLandmark.INDEX_FINGER_TIP]
                pixel_x = int(index_fingertip.x * imageWidth)
                pixel_y = int(index_fingertip.y * imageHeight)

                # Mengecek apakah ujung jari menyentuh musuh (skor bertambah)
                if abs(pixel_x - x_enemy) < umpan_radius and abs(pixel_y - y_enemy) < umpan_radius:
                    score += 1
                    x_enemy = random.randint(50, 600)
                    y_enemy = random.randint(50, 400)
                    snake_length += 1

                    # Mengatur ulang posisi obstacle secara acak
                    x_obstacle = random.randint(50, 600)
                    y_obstacle = random.randint(50, 400)

                # Mengecek apakah ular menabrak rintangan (game over)
                if (x_obstacle <= pixel_x <= x_obstacle + obstacle_width and
                    y_obstacle <= pixel_y <= y_obstacle + obstacle_height):
                    if game_over_time is None:
                        game_over_time = time.time()  # Menyimpan waktu game over
                    cv2.putText(image, "Game Over", (250, 250), font, 1, (0, 0, 255), 3, cv2.LINE_AA)
                    cv2.imshow('Hand Tracking Game', image)
                    cv2.waitKey(2000)  # Menunggu 2 detik sebelum keluar
                    score = 0  # Reset skor
                    game_over_time = None  # Reset variabel waktu game over
                    x_obstacle = random.randint(50, 600)  # Mengatur ulang posisi obstacle secara acak

                # Menggerakkan ular (menambah panjang)
                move_snake(pixel_x, pixel_y)

        # Menggambar ular dengan variasi warna
        draw_snake(image)

        cv2.imshow('Hand Tracking Game', image)

        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

video.release()
cv2.destroyAllWindows()
