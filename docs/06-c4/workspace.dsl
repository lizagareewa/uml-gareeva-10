workspace "Система продажи билетов" "Учебная модель" {
    model {

        viewer = person "Зритель" "Ищет события, покупает билеты и абонементы"
        cashier = person "Кассир" "Продаёт билеты в кассах стадиона"
        admin = person "Администратор" "Управляет возвратами и справочниками"

        payment_gw = softwareSystem "Платёжный шлюз" "Обработка платежей" "Внешняя"
        email_sys = softwareSystem "Email/SMS-шлюз" "Рассылка билетов" "Внешняя"

        stadium_sys = softwareSystem "Система продажи билетов" {
            web_ui = container "Веб-витрина" "Выбор мест, оформление заказа" "React"
            pos_ui = container "АРМ Кассира" "Рабочее место кассира" "WPF / .NET"
            
            db = container "Основная БД" "Хранение каталога, заказов" "PostgreSQL" "Database"
            queue = container "Очередь событий" "Асинхронные задачи" "RabbitMQ" "Queue"
            worker = container "Воркер рассылок" "Генерация PDF и писем" "Python"

            api = container "Backend API" "Основная бизнес-логика" "Java, Spring Boot" {
                order_ctrl = component "OrderController" "Эндпоинты заказов" "Spring MVC"
                seat_ctrl = component "SeatController" "Эндпоинты мест" "Spring MVC"
                
                order_svc = component "OrderService" "Оркестрация создания заказа" "Java"
                seat_svc = component "SeatService" "Управление блокировками" "Java"
                payment_svc = component "PaymentService" "Интеграция с эквайрингом" "Java"
                
                repo = component "JPA Repositories" "Доступ к БД" "Spring Data"
                event_pub = component "EventPublisher" "Отправка сообщений" "Java"
            }
        }

        viewer -> web_ui "Пользуется" "HTTPS"
        cashier -> pos_ui "Пользуется" "HTTPS"
        admin -> web_ui "Оформляет возвраты" "HTTPS"

        web_ui -> order_ctrl "POST /orders" "JSON/HTTPS"
        web_ui -> seat_ctrl "GET /seats" "JSON/HTTPS"
        pos_ui -> api "Вызывает" "JSON/HTTPS"

        order_ctrl -> order_svc "Вызывает"
        seat_ctrl -> seat_svc "Вызывает"
        
        order_svc -> seat_svc "Проверяет и блокирует"
        order_svc -> payment_svc "Инициирует оплату"
        order_svc -> repo "Сохраняет сущности"
        order_svc -> event_pub "Публикует успешный заказ"
        
        seat_svc -> repo "Использует"
        
        // Связи с базами, очередями и внешними системами
        payment_svc -> payment_gw "Запрашивает авторизацию" "HTTPS"
        repo -> db "Читает и пишет" "JDBC"
        event_pub -> queue "Отправляет" "AMQP"

        queue -> worker "Доставляет события" "AMQP"
        worker -> db "Читает данные заказа" "JDBC"
        worker -> email_sys "Отправляет PDF-билет" "SMTP"
    }

    views {
        systemContext stadium_sys "Context" {
            include *
            autolayout lr
        }
        container stadium_sys "Containers" {
            include *
            autolayout lr
        }
        component api "Components" {
            include *
            autolayout lr
        }
        theme default
    }
}