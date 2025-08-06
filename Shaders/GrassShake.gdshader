shader_type canvas_item;

// Настройки ветра
uniform float wind_strength = 0.05;
uniform float wind_speed = 2.0;
uniform vec2 wind_direction = vec2(1.0, 0.0);
uniform float grass_height = 0.5;

void vertex() {
    // Анимируем только верхнюю часть травы (где grass_height определяет, какая часть будет двигаться)
    if (UV.y > (1.0 - grass_height)) {
        // Синусоидальное движение с разной частотой для разных частей
        float wave = sin(TIME * wind_speed + UV.x * 10.0) * wind_strength;

        // Применяем смещение в направлении ветра
        VERTEX += vec2(wave * wind_direction.x, wave * wind_direction.y * 0.3);
    }
}