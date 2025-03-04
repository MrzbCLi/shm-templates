{{ MACRO sendAlert BLOCK }}
    {
        "answerCallbackQuery": {
            "callback_query_id": {{ callback_query.id }},
            "parse_mode":"HTML",
            "text": "{{ errtext.replace('\n','\n') }}",
            "show_alert": true
        }
    }
    {{ IF redirect }}
        ,{
            "shmRedirectCallback": {
                "callback_data": "{{ redirect }}"
            }
        }
    {{ END }}
    {{ STOP }}
{{ END }}

{{ MACRO redirect BLOCK }}
    {
        "shmRedirectCallback": { "callback_data": "{{ callback }}" }
    }
    {{ STOP }}
{{ END }}

{{
    # Get data from storage
    storageMessageType = user.id(1).storage.read('name', 'bot_configuration').messageType;
    storageMenuCmd = user.id(1).storage.read('name', 'bot_configuration').menuCmd;
    storageCheckNotPaidServices = user.id(1).storage.read('name', 'bot_configuration').checkNotPaidServices;
}}

<%# Check for admin rights from user settings %>
<%# for use admin menu, set role = "admin" or "moderator" %>
{{ BLOCK checkAdminRights }}
    {{ IF user.settings.role != "admin" && user.settings.role != "moderator" }}
        {{ sendAlert(code=403, errtext='⭕️ Раздел закрыт', redirect=mainMenuCmd) }}
    {{ END }}
{{ END }}


<%# Check for moderator rights %>
{{ MACRO checkModeratorRights BLOCK }}
    {{ IF user.settings.role == "moderator" && user.settings.moderate.$right != 1 }}
        {{ sendAlert(code=403, errtext="⭕️ Доступ запрещён!", redirect=mainMenuCmd) }}
    {{ END }}
{{ END }}

<%# sendMessage or editMessageText functional %>
{{ MACRO send BLOCK }}
    {{
        messageType =
            (cmd == '/start') ? 'sendMessage' :
            (cmd == '/menu' && mainMenuCmd == '/menu') ? 'editMessageText' :
            (mainMenuCmd == '/start' || cmd == '/start') ? 'sendMessage' :
            (edit == 0) ? 'sendMessage' :
            (edit == 1) ? 'editMessageText' :
            (defaultMessageType == 'editMessageText' ) ? 'editMessageText' :
            defaultMessageType;

        # Clear state
        ret = user.set_settings({'state' => ''});

        IF user.settings.bot.reqPromo > 0;
            delete(msgID=[user.settings.bot.reqPromo]);
            ret = user.set_settings({'bot' => {'reqPromo' => ''} });
        END;

        IF (cmd != '/start' && !edit && messageType != 'editMessageText' );
            delete(msgID=[message.message_id]);
        END; 
        
        # variable check for admin rights to access admin menu
        IF admin == 1;
            PROCESS checkAdminRights;
        END;
    }}
    {
        "sendChatAction": {
            "chat_id": "{{ user.settings.telegram.chat_id }}",
            "action": "typing"
        }
    },
    {
        "{{messageType}}": {
            {{ IF messageType == 'editMessageText'}}
                "message_id": "{{ message.message_id }}",
            {{ END }}
            "parse_mode": "HTML",
            "text": "{{ TEXT.replace('\n','\n') }}",
            "reply_markup": {
                "inline_keyboard": [
                    {{ BUTTONS }}
                ]
            }
        }
    }
{{ END }}

{{ MACRO notification BLOCK }}
    {
        "sendMessage": {
            "parse_mode": "HTML",
            "text": "{{ TEXT.replace('\n','\n') }}",
            "reply_markup": {
            {{ IF force == 1 }}
                "force_reply": true,
                "input_field_placeholder": "{{ placeholder }}"
            {{ END }}
            {{ IF BUTTONS }}
                "inline_keyboard": [
                    {{ BUTTONS }}
                ]
            {{ END }}
            }
        }
    }
{{ END }}

{{ MACRO delete BLOCK }}
{
    "deleteMessages": { "chat_id": {{ user.settings.telegram.chat_id }}, "message_ids": {{ toJson(msgID) }} }
},
{{ END }}

{{ MACRO cancelRegistration BLOCK }}
{
    "sendMessage": {
        "text": "❌ Вы отменили регистрацию. Если хотите начать заново, нажмите /start.",
        "parse_mode": "HTML"
    }
}
{{ STOP }}
{{ END }}

{{ BLOCK send }}
{
    "sendPhoto": {
        "photo": "{{ config.setting_tgmy_bot.logoUrl }}",
        "caption": "{{ text.replace('\n','\n') }}",
        "parse_mode": "HTML",
        "reply_markup": {
            "inline_keyboard": [
                {{ buttons }}
            ]
        }
    }
}
{{ END }}

<% SWITCH cmd %>
<% CASE 'cancel_registration' %>
{
        "deleteMessage": { "message_id": "{{ message.message_id }}" }
},
    {
        "sendMessage": {
            "text": "❌ Вы отменили регистрацию. Если хотите начать заново, нажмите /start.",
            "parse_mode": "HTML"
        }
    }
<% CASE 'USER_NOT_FOUND' %>
    {
        "sendMessage": {
            "text": "<b>BatutVPN — ваша защита в мире интернета!</b>\n\n🌐 Мы обеспечиваем надежное шифрование вашего интернет-трафика, что помогает защитить ваши личные данные от хакеров и мошенников.\n\n🚀 <b>BatutVPN</b> предлагает высокоскоростные сервера, обеспечивая отличное качество соединения для стриминга, игр и серфинга.\n\n🌍 Подключайтесь к серверам в разных странах, включая 🇷🇺Россия, 🇩🇪Германию, 🇪🇸Испания и другие. \nПолучите доступ к контенту со всего мира!\n\n📱 Простой и интуитивно понятный интерфейс, доступный на всех устройствах:\n 🖥Windows, 💻macOS, 📱Android, 📱iOS и 📺TV.\n\n🛡️ Наша команда поддержки всегда готова Вам помочь!\n\n<b>Выбирайте BatutVPN — безопасность и свобода в интернете на одном щелчке!</b>\n\n<i>Нажимая кнопку '✅ Продолжить', Вы принимаете условия Пользовательского соглашения.</i>",
            "parse_mode": "HTML",
            "photo": "{{ config.setting_tgmy_bot.logoUrl }}",
            "reply_markup": {
                "inline_keyboard": [
                    [
                        {
                            "text": "Соглашение",
                            "web_app": {
                                "url": "{{ config.setting_tgmy_bot.PolitikaUrl }}"
                            }
                        }
                    ],
                    [
                        {
                            "text": "✅ Продолжить",
                            "callback_data": "/register {{ args.0 }}"
                        },
                        {
                            "text": "❌ Нет",
                            "callback_data": "cancel_registration"
                        }
                    ]
                ]
            }
        }
    }
<% CASE '/register' %>
    {
        "deleteMessage": { "message_id": "{{ message.message_id }}" }
    },
    {
        "shmRegister": {
            "partner_id": "{{ args.0 }}",
            "callback_data": "/start",
            "error": "ОШИБКА: Логин {{ message.chat.username }} или chat_id {{ message.chat.id }} уже существует"
        }
}

<% CASE ['/start', '/menu', '🌍 Главное Меню', '🔄 Обновить'] %>
{{   # variables
     messageType = (cmd == '/menu') ? 1 : 0;
}}
{
    "deleteMessage": { 
        "message_id": {{ message.message_id }} 
    }
},
{{ user_services = ref(user.services.list_for_api('filter', { 'category' => '%', status => 'ACTIVE' } )) }}
{{ TEXT = BLOCK }}
<b>Выбирайте BatutVPN — безопасность и свобода в интернете на одном щелчке!</b>
{{ END }}
{{ buttons = BLOCK }}
                {{ IF user.settings.role == 'moderator' || user.settings.role == 'admin' }}
                [
                    {
                        "text": "👨‍💻 Меню {{ menuRole = (user.settings.role == 'admin' ? 'администратора' : 'модератора'); menuRole }}",
                        "callback_data": "admin:menu"
                    }
                ],
                {{ END }}
                [
                    {
                        "text": "💰 Купить VPN ✅🛡",
                        "callback_data": "/pricelist"
                    }
                ],
                [
                    {
                        "text": "🧑‍💻 Мои VPN ключи 🔐",
                        "callback_data": "/list"
                    }
                ],
                [
                    {
                        "text": "⚙️ Аккаунт: {{ user.balance }} ₽",
                        "callback_data": "/balance"
                    }
                ],
                [
                    {
                        "text": "📖 Помощь и поддержка",
                        "callback_data": "/help"
                    }
                ],
                [
                    {
                        "text": "🔄 Обновить меню",
                        "callback_data": "/menu"
                    } 
                ]
{{ END }}
{{ process send text=TEXT buttons=buttons }}

<% CASE ['/profile', '/balance'] %>
{{
    limit = 5;
    offset = args.1 || 0;
    userData = user.id(args.0);
    userPays = ref(userData.pays.list_for_api('limit', limit, 'offset', offset ));
}}
{{ active_services = ref(user.services.list_for_api('category', '%', 'filter', { 'status' => 'ACTIVE' })) }}

{{ TEXT = BLOCK }}
<b>👤 Личный кабинет</b>

<b>🔹 Имя:</b> {{ user.full_name }}
<b>🔹 Логин:</b> {{ user.login }}
<b>🔹 ID:</b> {{ user.id }}
<b>💰 Баланс:</b> {{ user.balance }} ₽

<b>🚀 Активные услуги:</b>
{{ IF active_services.size > 0 }}
{{ FOR service IN active_services }}
- <code>{{ service.name }}</code> (до {{ service.expire }})
{{ END }}
{{ ELSE }}
Нет активных услуг.
{{ END }}

<b>👉 Выберите действие:</b>
{{ END }}

{{ buttons = BLOCK }}
                [
                    {
                        "text": "💳 Пополнить баланс: Карта РФ",
                        "web_app": {
                            "url": "{{ config.api.url }}/shm/v1/public/tg_payments_webapp?format=html&user_id={{ user.id }}"
                        }
                    }
                ],
                [
					{
                        "text": "📲 Пополнить баланс: Перевод, СБП",
                        "callback_data": "/topup"
                    }
                ],
                [
                    {
                        "text": "📜 История операций",
                        "callback_data": "/pays"
                    },
                    { "text": "🏷️ Ввести промокод", 
                    "web_app": { "url": "{{ config.api.url }}/shm/v1/public/promo?format=html&user_id={{ user.id }}" }
                    }
                ],
                [
                    {
                        "text": "🚀 Управление услугами",
                        "callback_data": "/list"
                    }
                ],
                [
                    {
                        "text": "🤝 Реферальная программа",
                        "callback_data": "/referrals"
                    }
                ],
                [
                    {
                        "text": "👨‍💻 Меню",
                        "callback_data": "/menu"
                    }
                ]
{{ END }}
{{ process send text=TEXT buttons=buttons }}

<% CASE '/manage_services' %>
{{ active_services = ref(user.services.list_for_api('filter', { 'status' => 'ACTIVE' })) }}
{{ expired_services = ref(user.services.list_for_api('filter', { 'status' => 'NOT PAID' })) }}
{{ # Variables
    active_services = user.services.list_for_api('usi', args.0);

    # Plugins
    USE date;
}}
{{ TEXT = BLOCK }}
🚀 <b>Управление услугами</b>

{{ IF active_services.size == 0 && expired_services.size == 0 }}
<i>Нет доступных услуг для управления.</i>
{{ ELSE }}
<b>✅ Активные услуги:</b>
{{ IF active_services.size > 0 }}
{{ FOR service IN active_services }}
- <b>{{ service.name }}</b> (до {{ date.format(service.expire, '%d.%m.%Y') }})
{{ END }}
{{ ELSE }}
<i>Нет активных услуг.</i>
{{ END }}

<b>❗️ Неоплаченные услуги:</b>
{{ IF expired_services.size > 0 }}
{{ FOR service IN expired_services }}
- <b>{{ service.name }}</b> (истёк {{ date.format(service.expire, '%d.%m.%Y') }})
{{ END }}
{{ ELSE }}
<i>Нет неоплаченных услуг.</i>
{{ END }}
{{ END }}

<b>👉 Выберите действие:</b>
{{ END }}

{{ buttons = BLOCK }}
                {{ IF active_services.size > 0 || expired_services.size > 0 }}
                {{
                    limit = 1;
                    offset = args.0 || 0;
                    offset = (offset < 0) ? 0 : offset;
                    active_services = ref(user.services.list_for_api('filter', { 'status' => 'ACTIVE' }, 'limit', limit, 'offset', offset));
                    expired_services = ref(user.services.list_for_api('filter', { 'status' => 'NOT PAID' }, 'limit', limit, 'offset', offset));
                }}
                {{ IF offset > 0 || active_services.size == limit || expired_services.size == limit }}
                [
                    {{ IF offset > 0 }}
                    {
                        "text": "⬅️ Назад",
                        "callback_data": "/manage_services {{ offset - limit }}"
                    },
                    {{ END }}
                    {{ IF active_services.size == limit || expired_services.size == limit }}
                    {
                        "text": "➡️ Далее",
                        "callback_data": "/manage_services {{ offset + limit }}"
                    }
                    {{ END }}
                ],
                {{ END }}
                {{ END }}
                [
                    {
                        "text": "🛒 Купить услугу",
                        "callback_data": "/pricelist"
                    },
                    {
                        "text": "🔄 Обновить",
                        "callback_data": "/manage_services"
                    }
                ],
                [
                    {
                        "text": "🏠 Вернуться в меню",
                        "callback_data": "/menu"
                    }
                ]
{{ END }}
{{ process send text=TEXT buttons=buttons }}


<% CASE '/balance999' %>
{
    "deleteMessage": { "message_id": {{ message.message_id }} }
},
{{ userlogs = user.services.list_for_api('usi', {}) }}
{{
    limit = 5;
    offset = args.1 || 0;
    userData = user.id(args.0);
    payData = userPay.comment.object;
    payMethod = payData.payment_method;
    payCard = payMethod.card;
    userPays = ref(userData.pays.list_for_api('limit', limit, 'offset', offset ));
}}
{{ last_payment = user.payments.last() }}
{{ forecast = user.pays.forecast }}
{{ user_services = ref(user.services.list_for_api('category', '%')) }}
{{ blocked_services = ref(user.services.list_for_api('category', '%', 'filter', { 'status' => 'BLOCK' })) }}
{{ expired_services = ref(user.services.list_for_api('category', '%', 'filter', { 'status' => 'NOT PAID' })) }}
{{ active_services = ref(user.services.list_for_api('category', '%', 'filter', { 'status' => 'ACTIVE' })) }}
{{ USE date }}
{{ TEXT = BLOCK }}
💰 <b>Баланс:</b> {{ user.balance }} ₽  
🎁 <b>Бонусы:</b> {{ user.get_bonus }} ₽  
🔖 <b>Скидка:</b> {{ user.discount }}%  
👥 <b>Приглашено друзей:</b> {{ user.referrals_count }}  
💳 <b>Общий доход от рефералов:</b> {{ user.get_bonus }} ₽  

⏳ <b>Следующее продление:</b> 
{{ IF userlogs.expire }} 
  <i>{{ date.format(userlogs.expire, '%H:%M %d.%m.%Y') }}</i> 
{{ ELSE }} 
  <i>неизвестно</i> 
{{ END }}  

💵 <b>Ожидаемая оплата:</b> <i>{{ forecast.total }} ₽</i>  

<b>🔒 Заблокированные сервисы:</b>
{{ IF blocked_services.size > 0 }}
    {{ FOR service IN blocked_services }}
    - {{ service.name }}
    {{ END }}
{{ ELSE }}
    Нет заблокированных сервисов.
{{ END }}


<b>❗ Неоплаченные сервисы:</b>
{{ IF expired_services.size > 0 }}
    {{ FOR service IN expired_services }}
    - {{ service.name }}
    {{ END }}
{{ ELSE }}
    Нет неоплаченных сервисов.
{{ END }}

<b>✅ Активные услуги:</b>
{{ IF active_services.size > 0 }}
    {{ FOR service IN active_services }}
    - {{ service.name }} (до {{ date.format(service.expire, '%H:%M %d.%m.%Y') }})
    {{ END }}
{{ ELSE }}
    Нет активных услуг.
{{ END }}

💵 <b>Необходимо оплатить:</b> <b>{{ user.pays.forecast('blocked',1).total }} ₽</b>
{{ END }}

{{ buttons = BLOCK }}
                [
                    {
                        "text": "✚ Пополнить баланс",
                        "web_app": {
                            "url": "{{ config.api.url }}/shm/v1/public/tg_payments_webapp?format=html&user_id={{ user.id }}"
                        }
                    }
                ],
				 [{ "text": "🏷️ Ввести промокод", "callback_data": "promocode" }, { "text": "🏷️ Web", "web_app": { "url": "{{ config.api.url }}/shm/v1/public/promo?format=html&user_id={{ user.id }}" }}],
                [
									{
                        "text": "📜 Отправить квитанцию",
                        "callback_data": "/topup"
                    },
                    {
                        "text": "☰ История платежей",
                        "callback_data": "/pays"
                    }
                ],
                [
                    {
                        "text": "🔄 Обновить",
                        "callback_data": "/balance"
                    }
                ],
                [
                    {
                        "text": "⇦ Назад",
                        "callback_data": "/menu"
                    }
                ]
{{ END }}
{{ process send text=TEXT buttons=buttons }}

<% CASE '/pays' %>
{
    "sendMessage": {
        "text": "☰ <b>История платежей</b>",
        "reply_markup": {
            "inline_keyboard": [
                {{
                    limit = 7;
                    offset = args.0 || 0;
                    offset = (offset < 0) ? 0 : offset;
                    pays = ref(user.pays.list_for_api('limit', limit, 'offset', offset));
                }}
                {{ IF pays.size > 0 }}
                    {{ FOR item in pays }}
                    [
                        {
                            "text": "📅 Дата: {{ item.date }} | 💰 {{ item.money }} руб.",
                            "callback_data": "/checkpay {{ item.id }}"
                        }
                    ],
                    {{ END }}
                {{ ELSE }}
                    [
                        {
                            "text": "❗️ Нет записей о платежах.",
                            "callback_data": "/menu"
                        }
                    ],
                {{ END }}
                {{ IF pays.size == limit || offset > 0 }}
                [
                    {{ IF offset > 0 }}
                    {
                        "text": "⬅️ Назад",
                        "callback_data": "/pays {{ offset - limit }}"
                    },
                    {{ END }}
                    {{ IF pays.size == limit }}
                    {
                        "text": "➡️ Далее",
                        "callback_data": "/pays {{ offset + limit }}"
                    }
                    {{ END }}
                ],
                {{ END }}
                [
                    {
                        "text": "🏠 Главное меню",
                        "callback_data": "/menu"
                    }
                ]
            ]
        }
    }
}


<% CASE 'user:pays' %>
{{
    # Variables
    limit = 5;
    offset = args.0 || 0;
    pays = ref(user.pays.list_for_api('limit', limit, 'offset', offset ));
}}
{{ TEXT = BLOCK }}
☰ <b>История платежей</b>
{{ END }}

{{ buttons = BLOCK }}
    {{ FOR item in pays }}
        [
            {
                "text": "Дата: {{ item.date }}, Сумма: {{ item.money }} руб.",
                "callback_data": "user:cabinet"
            }
        ],
    {{ END }}
    {{ IF pays.size == limit || offset > 0 }}
        [
        {{ IF offset > 0 }}
            {
                "text": "⬅️ Назад",
                "callback_data": "user:pays {{ offset - limit }}"
            },
        {{ END }}
        {{ IF pays.size == limit }}
            {
                "text": "Ещё ➡️",
                "callback_data": "user:pays {{ limit + offset }}"
            }
        {{ END }}
        ],
    {{ END }}
    [
        {
            "text": "🏠 Главное меню",
            "callback_data": "{{ mainMenuCmd }}"
        }
    ]
{{ END }}
{{ PROCESS send text=TEXT buttons=buttons}}

<% CASE '/checkpay' %>
{
    "deleteMessage": { "message_id": {{ message.message_id }} }
},
{{
    userPay = ref(pay.list_for_api('limit', 1, 'filter', {"id" = args.0})).first;
    payData = userPay.comment.object;
    payMethod = payData.payment_method;
    payCard = payMethod.card;
    userData = user.id(userPay.user_id);
}}
{{ TEXT = BLOCK }}
💸 <b>Информация о платеже</b>
🆔 <b>ID платежа:</b> {{ userPay.id }}
👤 <b>Пользователь:</b> {{ userData.full_name.replace('"', '"') }} ({{ userData.user_id }})

📅 <b>Дата платежа:</b> {{ userPay.date }}
💳 <b>Платежная система:</b> {{ userPay.pay_system_id }}
💰 <b>Сумма:</b> {{ userPay.money }} руб.

{{ IF userPay.telegram_bot == 'telegram_bot' }}
⭐ <b>Оплата звездами:</b> {{ userPay.currency }}
{{ END }}

{{ IF userPay.currency == 'XTR' }}
⭐ <b>Оплата звездами:</b> {{ userPay.currency }}
{{ END }}

{{ IF userPay.comment.comment }}
📝 <b>Комментарий к платежу:</b>
<blockquote>{{ userPay.comment.comment }}</blockquote>
{{ END }}

{{ IF payData }}
📂 <b>Детали платежа:</b>
<blockquote> 🆔 <b>ID в системе:</b> {{ payData.id }}
📊 <b>Статус:</b> {{ payData.status }}
{{ IF payCard }}
Тип карты: {{ payCard.card_type }}
Номер карты: {{ payCard.first6 }}******{{ payCard.last4 }}
Банк: {{ payCard.issuer_name }}
Страна банка: {{ payCard.issuer_country }}
Срок действия: {{ payCard.expiry_month }}/{{ payCard.expiry_year }}
{{ END }}
{{ IF payMethod.type == 'sbp' }}
Тип оплаты: СБП
Номер операции в СБП: {{ payMethod.sbp_operation_id }}
Бик Банка: {{ payMethod.payer_bank_details.bic }}
{{ END }}

{{ IF payMethod.title.match('YooMoney') }}
Кошелек YooMoney: {{ payMethod.title }}
ID кошелька: {{ payMethod.account_number }}
{{ END }}
</blockquote>
{{ END }}

{{ END }}

{
    "sendMessage": {
        "text": "{{ TEXT.replace('\n','\n') }}\n",
        "reply_markup": {
            "inline_keyboard": [
                [
                    {
                        "text": "🔄 Обновить",
                        "callback_data": "/checkpay {{ args.0 }}"
                    }
                ],
                [
                    {
                        "text": "⇦ Назад ⇦",
                        "callback_data": "/pays"
                    }
                ]
            ]
        }
    }
}

<% CASE '/list' %>
{{ item = us.id(args.0) }}
{
    "deleteMessage": { "message_id": {{ message.message_id }} }
},
{{ services = ref(user.services.list_for_api('category', '%')) }}
{{ TEXT = BLOCK }}
⭐️ <b>Ваш ID:</b> {{ user.id }} ⭐️

💡 <i>Для получения подробной информации о вашем ключе, просто нажмите на его название ниже.</i>

❇️ <b>Для продления или разблокировки ключа:</b> Пополните баланс. Ваши ключи будут активированы сразу после оплаты.

🔑 <b>Ваши текущие ключи:</b>
{{ END }}

{{ IF services.size > 0 }}
{
    "sendMessage": {
        "text": "{{ TEXT.replace('\n','\n') }}",
        "reply_markup" : {
            "inline_keyboard": [
                {{ FOR item IN services }}
                {{ SWITCH item.status }}
                    {{ CASE 'ACTIVE' }}
                        {{ icon = '✅' }}
                        {{ status = 'Работает' }}
                    {{ CASE 'BLOCK' }}
                        {{ icon = '❌' }}
                        {{ status = 'Заблокирована' }}
                    {{ CASE 'NOT PAID' }}
                        {{ icon = '💵' }}
                        {{ status = 'Ожидает оплаты' }}
                    {{ CASE }}
                        {{ icon = '⏳' }}
                        {{ status = 'Обработка' }}
                {{ END }}
                [
                    {
                        "text": "{{ item.name }} 🆔{{ item.user_service_id }} - {{ icon }} {{ status }}",
                        {{ IF item.status == 'NOT PAID' }}
                        "callback_data": "/service {{ item.user_service_id }}"
                        {{ ELSIF item.category != 'vpn-mz-tv' }}
                        "callback_data": "/service {{ item.user_service_id }}"
                        {{ ELSIF item.category == 'vpn-mz-tv' }}
                        "callback_data": "/setup_android {{ item.user_service_id }}"
                        {{ END }}
                    }
                ],
                {{ END }}
                [
                    {
                        "text": "✚ Купить новый ключ",
                        "callback_data": "/pricelist"
                    }
                ],
				[
                    {
                        "text": "🔄 Обновить список 🔄",
                        "callback_data": "/list"
                    }
                ],
                [
                    {
                        "text": "🏠 Главное меню",
                        "callback_data": "/menu"
                    }
                ]
            ]
        }
    }
}
{{ ELSE }}
{
    "sendMessage": {
        "text": "❌ У вас нет активных или неоплаченных ключей.",
        "reply_markup": {
            "inline_keyboard": [
                [
                    {
                        "text": "✚ Купить ключ",
                        "callback_data": "/pricelist"
                    }
                ],
                [
                    {
                        "text": "🏠 Главное меню",
                        "callback_data": "/menu"
                    }
                ]
            ]
        }
    }
}
{{ END }}


<% CASE '/hint' %>
{
    "sendMessage": {
        "chat_id": {{ message.chat.id }},
        "parse_mode": "HTML",
        "text": "⚠️ **Внимание!** Чтобы продолжить, пожалуйста, выполните одно из следующих действий:\n\n1️⃣ Оплатите  💳  все неоплаченные услуги.\n2️⃣ Удалите  🗑️  все заблокированные услуги.\n\nЭто необходимо для корректной работы вашей учетной записи. Спасибо за понимание! 🙏",
        "reply_markup": {
            "inline_keyboard": [
                [
                    {
                        "text": "Перейти в меню",
                        "callback_data": "/menu"
                    }
                ]
            ]
        }
    }
}

<% CASE '/service' %>
{
    "deleteMessage": { "message_id": {{ message.message_id }} }
},
{{ item = us.id(args.0) }}
{{ us = user.services.list_for_api( 'usi', args.0 ) }}
{{ EXPIRE = BLOCK }}
    {{ USE date }}
    {{ date_sec = date.now }}
    {{ expire_sec = date.format(us.expire, '%s') }}
    {{ days_left = (expire_sec - date_sec) div 86400 }}
    {{ months = days_left div 30 }}
    {{ days = days_left % 30 }}
        {{ IF months == 0 }}
            {{ IF days == 1 }} 1 день
            {{ ELSIF days == 2 or days == 3 or days == 4 }} {{ days }} дня
            {{ ELSE }} {{ days }} дней
            {{ END }}
        {{ ELSE }}
            {{ IF months == 1 }}1 месяц - 
            {{ ELSIF months == 2 or months == 3 or months == 4 }}{{ months }} месяца - 
            {{ ELSE }}{{ months }} месяцев - 
            {{ END }}
            {{ IF days > 0 }}
                {{ IF days == 1 }} 1 день
                {{ ELSIF days == 2 or days == 3 or days == 4 }} {{ days }} дня
                {{ ELSE }} {{ days }} дней
                {{ END }}
            {{ END }}
        {{ END }}
{{ END }}
{{ sub_url = storage.read('name','vpn_mrzb_' _ args.0 ).subscription_url }}
{{ bytes = http.get("$sub_url/info").used_traffic }}
{{ gb = bytes / 1073741824 FILTER format("%.0f") }}
{{ mb = (bytes % 1073741824) / 1048576 FILTER format("%.0f") }}
{
    "sendPhoto": {
        {{ SWITCH us.status }}
  {{ CASE 'ACTIVE' }}
  {{ icon = '✅' }}
  {{ status = 'Работает' }}
  {{ CASE 'BLOCK' }}
  {{ icon = '🚫' }}
  {{ status = 'Заблокирована' }}
  {{ CASE 'NOT PAID' }}
  {{ icon = '💳' }}
  {{ status = 'Ожидает оплаты' }}
  {{ CASE }}
  {{ icon = '⏳' }}
  {{ status = 'Обработка' }}
{{ END }}
{{ TEXT = BLOCK }}
<b>Услуга</b>: {{ us.name }}
    {{ IF us.expire }}
<b>🗓️ Оплачена до</b>: {{ us.expire }}
    {{ END }}
<b>📊 Статус</b>: {{ icon}} {{ status }}
    {{ IF mb == 0 }}
    {{ ELSE}}
        {{ IF gb >= 1 }}
📈 Израсходовано трафика: {{ gb }} Gb.{{ mb }} Mb
        {{ ELSE }}
📈 Израсходовано трафика: {{ mb }} Mb
        {{ END }}
    {{ END }}
{{ END }}
        "photo": "{{ config.setting_tgmy_bot.logoUrl }}",
        "caption": "{{ TEXT.replace('\n','\n') }}\n📅 Осталось: <b>{{ EXPIRE }}</b> -- {{ COST }}",
        "parse_mode": "HTML",
        "reply_markup": {
            "inline_keyboard": [
                {{ IF us.status == 'ACTIVE' }}
                    {{ subscription_url = storage.read('name', 'vpn_mrzb_' _ us.user_service_id).subscription_url }}
                    {{ IF us.category.grep('^vpn-mz-').first && subscription_url.grep('^https:').first }}
                        [
                            {
                                "text": "🔗 Подключиться",
                                "web_app": {
                                    "url": "{{ config.api.url }}/shm/v1/template/subscriptions_link?format=html&session_id={{ user.gen_session.id }}&uid={{ user.id }}&us_id={{ args.0 }}"
                                }
                            }
                        ],
                        [
                            {
                                "text": "🌐 Показать ссылку подписки",
                                "callback_data": "/show_mz_keys {{ us.user_service_id }}"
                            }
                        ],
                    {{ ELSE }}
                        [
                            {
                                "text": "😢 Ошибка: подключение не найдено",
                                "callback_data": "/menu"
                            }
                        ],
                    {{ END }}
                {{ ELSIF us.status == 'NOT PAID' || us.status == 'BLOCK' }}
                    [
                        {
                            "text": "💳 Оплатить",
                            "callback_data": "/balance {{ us.user_service_id }}"
                        }
                    ],
                    [
                        {
                            "text": "🗑️ Удалить ключ",
                            "callback_data": "/delete {{ us.user_service_id }}"
                        }
                    ],
                {{ END }}
                [
                    {
                        "text": "♻️ Сменить тариф",
                        "callback_data": "/change {{ us.user_service_id }}"
                    }
                ],
                [
                    {
                        "text": "🔄 Обновить информацию",
                        "callback_data": "/service {{ args.0 }}"
                    }
                ],
                [
                    {
                        "text": "↩️ Назад к списку услуг",
                        "callback_data": "/list"
                    }
                ]
            ]
        }
    }
}

<% CASE '/change' %>
{
    "deleteMessage": { "message_id": {{ message.message_id }} }
},
{
    "sendMessage": {
        "parse_mode": "HTML",
        "text": "📋 **Выберите тариф для смены:**\n\n🔄 Вы можете выбрать один из доступных тарифов ниже. Цены указаны в рублях (₽).",
        "reply_markup": {
            "inline_keyboard": [
                {{ FOR item IN ref(service.api_price_list( 'category', 'vpn-%' )).nsort('cost') }}
                    [
                        {
                            "text": "💼 {{ item.name }} — {{ item.cost }} ₽",
                            "callback_data": "/change_id {{ args.0 _ ' ' _ item.service_id }}"
                        }
                    ],
                {{ END }}
                [
                    {
                        "text": "🏠 Главное меню",
                        "callback_data": "/menu"
                    }
                ]
            ]
        }
    }
}

<% CASE '/change_id' %>
{
    "deleteMessage": { "message_id": {{ message.message_id }} }
},
{{ change = us.id( args.0 ).change( service_id = args.1 ) }}
{{ TEXT = BLOCK }}
🎉 <b>Тариф успешно изменён!</b> 🚀

📝 <b>Ваш новый тариф:</b>  
{{ FOR item IN ref(service.list_for_api('service_id', args.1 )) }}
🔹 <b>{{ item.name }}</b>
{{ END }}

✅ <b>Изменение тарифа прошло успешно!</b>

{{ IF user.pays.forecast('blocked',1).total > 0 }}
💳 <b>Доплата необходима!</b>  
Для дальнейшего использования необходимо доплатить разницу по новому тарифу.  
💡 Остаток суммы предыдущего тарифа будет учтён.  
💵 <b>Сумма к доплате:</b> <code>{{ user.pays.forecast('blocked', 1).total }}₽</code>

{{ us.finish('money_back', 1) }}
{{ END }}
{{ END }}
{
    "sendMessage": {
        "text": "{{ TEXT.replace('\n','\n') }}",
        "parse_mode": "HTML",
        "reply_markup" : {
            "inline_keyboard": [
                [
                    {
                        "text": "🔙 Назад в меню",
                        "callback_data": "/menu"
                    }
                ]
            ]
        }
    }
}



<% CASE '/renewal' %>
{
    "deleteMessage": { "message_id": {{ message.message_id }} }
},
{{ us = us.id(args.0) }}
{{ IF us.next == '-1' }}
    {{ tkas = us.set('next',) }}
    {{ renewal_status = "✅ Автопродление успешно включено!" }}
    {{ renewal_hint = "Теперь услуга будет автоматически продлеваться при наличии средств на балансе." }}
{{ ELSE }}
    {{ tkas = us.set('next', -1) }}
    {{ renewal_status = "❌ Автопродление отключено!" }}
    {{ renewal_hint = "Услуга больше не будет автоматически продлеваться. Вы сможете продлить её вручную." }}
{{ END }}
{
    "deleteMessage": { "message_id": {{ message.message_id }} }
},
{
    "sendMessage": {
        "text": "🔄 <b>Статус автопродления</b>\n\n{{ renewal_status }}\n\nℹ️ {{ renewal_hint }}",
        "parse_mode": "HTML",
        "reply_markup": {
            "inline_keyboard": [
                [
                    {
                        "text": "⬅️ Вернуться к услуге",
                        "callback_data": "/service {{ args.0 }}"
                    }
                ]
            ]
        }
    }
}

<% CASE '/pricelist' %>
{{ IF checkNotPaidServices == 1 }}
    {{ notPaid = user.services.list_for_api('filter', { 'status' => 'NOT PAID' }, 'limit', 1) }}
    {{ IF ref(notPaid).size == 1 }}
        {
            "sendAlert": {
                "errtext": "⭕️ У вас имеется неоплаченный ключ\n🔑 #{{ notPaid.user_service_id }} - {{ notPaid.name }}\nОплатите, либо удалите его для покупки нового.",
                "redirect": "/service {{ notPaid.user_service_id }}"
            }
        },
        {{ STOP }}
    {{ END }}
{{ END }}

{
    "deleteMessage": { "message_id": {{ message.message_id }} }
},
{{ TEXT = BLOCK }}
<i>Мы предлагаем гибкие тарифы с разными сроками действия. Выберите подходящий план:</i>
{{ END }}
{
    "sendMessage": {
        "text": "{{ TEXT.replace('\n','\n') }}\n",
        "reply_markup": {
            "inline_keyboard": [
                {{ FOR item IN ref(service.api_price_list).nsort('cost') }}
                [
                    {
                        "text": "{{ item.name }} - {{ item.cost }} руб/мес.",
                        "callback_data": "/serviceorder {{ item.service_id }}"
                    }
                ],
                {{ END }}
                [
                    {
                        "text": "⇦ Назад",
                        "callback_data": "/menu"
                    }
                ]
            ]
        }
    }
}

<% CASE '/pricelist_android_tv' %>
{{ hasnotpaidus = ref(user.services.list_for_api('category', '%', 'filter', { 'status' => 'NOT PAID' } )).size }}
{{ hasblocked = ref(user.services.list_for_api('category', '%', 'filter', { 'status' => 'BLOCK' } )).size }}
{
    "deleteMessage": { "message_id": {{ message.message_id }} }
},
{{ TEXT = BLOCK }}
<i>Мы предлагаем гибкие тарифы с разными сроками действия. Выберите подходящий план:</i>
{{ END }}
{
    "sendMessage": {
        "text": "{{ TEXT.replace('\n','\n') }}\n",
        "reply_markup": {
            "inline_keyboard": [
                {{ FOR item IN ref( user.services.list_for_api( 'category', 'vpn-mz-tv' ) ) }}
                [
                    {
                        "text": "{{ item.name }} - {{ item.cost }} руб/мес.",
                        {{ IF hasnotpaidus > 0 || hasblocked > 0 }}
                            "callback_data": "/hint"
                        {{ ELSE }}
                            "callback_data": "/serviceorder {{ item.service_id }}"
                        {{ END }}
                    }
                ],
                [
                    {
                        "text": "{{ item.name }} - {{ item.cost * 6 }} руб/6 мес.",
                        {{ IF hasnotpaidus > 0 || hasblocked > 0 }}
                            "callback_data": "/hint"
                        {{ ELSE }}
                            "callback_data": "/serviceorder {{ item.service_id }} duration:6"
                        {{ END }}
                    }
                ],
                [
                    {
                        "text": "{{ item.name }} - {{ item.cost * 12 }} руб/12 мес.",
                        {{ IF hasnotpaidus > 0 || hasblocked > 0 }}
                            "callback_data": "/hint"
                        {{ ELSE }}
                            "callback_data": "/serviceorder {{ item.service_id }} duration:12"
                        {{ END }}
                    }
                ],
                {{ END }}
                [
					{
                        "text": "⇦ Назад",
                        "callback_data": "/list_android_tv"
                    }
                ]
            ]
        }
    }
}

<% CASE '/serviceorder' %>
{
    "shmServiceOrder": {
        "service_id": "{{ args.0 }}",
        "check_exists_unpaid": 1,
        "callback_data": "/pocessing",
        "cb_not_enough_money": "/pocessing",
        "error": "ОШИБКА"
    }
},

<% CASE ['/pocessing'] %>
{
    "editMessageText": {
        "message_id": {{ message.message_id }},
        "text": "Создаем услугу...",
        "parse_mode": "HTML"
    }
}

<% CASE '/nn123' %>
{
    "sendMessage": {
        "text": "❌ Вы отменили регистрацию. Если хотите начать заново, нажмите /start.",
        "parse_mode": "HTML",
        "photo": "{{ config.setting_tgmy_bot.logoUrl }}",
    }
},
{
    "sendAnimation": {
        "chat_id": {{ message.chat.id }},
        "protect_content": true,
        "animation": "{{ config.setting_tgmy_bot.loadingUrl }}",

    }
},
{
    "sendMessage": {
        "text": "❌ Вы отменили регистрацию. Если хотите начать заново, нажмите /start.",
        "parse_mode": "HTML"
    }
}

<% CASE '/notifications_active' %>
{{ item = us.id( args.0 ) }}
{{ subscription_url = storage.read('name','vpn_mrzb_' _ args.0 ).subscription_url }}
{{ TEXT = BLOCK }}
🎉 <b>🎊 Услуга успешно активирована!</b> 🚀  

<b>🔹 Название услуги:</b> <code>{{ item.name }}</code>
<b>🔹 ID услуги:</b>  № <code>{{ item.user_service_id }}</code>
<b>✅ Статус:</b> Активирована

<b>📅 Дата активации:</b> {{ USE date }}{{ date.format( item.created, '%d.%m.%Yг. %H:%M') }}
<b>⏳ До:</b> {{ USE date }}{{ date.format( item.expire, '%d.%m.%Yг. %H:%M') }}

<b>👉 Для автоматического подключения перейдите по кнопке ниже.</b>
{{ END }}
{
    "sendMessage": {
        "text": "{{ TEXT.replace('\n','\n') }}\n",
        "parse_mode": "HTML",
        "reply_markup": {
            "inline_keyboard": [
                [
                    {
                        "text": "🚀 Подключить автоматически",
                        "web_app": {
                            "url": "{{ config.api.url }}/shm/v1/template/subscriptions_link?format=html&session_id={{ user.gen_session.id }}&uid={{ user.id }}&us_id={{ args.0 }}"
                        }
                    }
                ],
                [
                    {
                        "text": "🏠 Вернуться в меню",
                        "callback_data": "/start"
                    }
                ]
            ]
        }
    }
}

<% CASE '/notifications_block' %>
{{ item = us.id(args.0) }}
{{ us = user.services.list_for_api( 'usi', args.0 ) }}
{{ subscription_url = storage.read('name','vpn_mrzb_' _ args.0 ).subscription_url }}
{{ IF event_name == "BLOCK" }}
{{ TEXT = BLOCK }}
<b>🚫 Внимание! Ваша подписка заблокирована!</b>

<b>🔹 Название услуги:</b> <code>{{ item.name }}</code>
<b>🔹 ID услуги:</b> № <code>{{ item.user_service_id }}</code>
<b>⚠️ Статус:</b> Заблокирована

<b>💰 Сумма к оплате:</b> <i>{{ user.pays.forecast('blocked', 1).total }}₽</i>

<b>❗ Причина блокировки:</b> <i>Недостаточно средств на счете. Пополните баланс, чтобы продолжить обслуживание.</i> 💳

<b>👉 Для восстановления доступа, пожалуйста, пополните счет и свяжитесь с нашей поддержкой.</b>
{{ END }}
{{ END }}

{
    "sendMessage": {
        "text": "{{ TEXT.replace('\n','\n') }}\n",
        "parse_mode": "HTML",
        "reply_markup": {
            "inline_keyboard": [
                {{ IF us.status == 'NOT PAID' || us.status == 'BLOCK' }}
                [
                    {
                        "text": "💳 Оплатить сейчас",
                        "callback_data": "/profile {{ user.pays.forecast('blocked', 1).total }}"
                    }
                ],
                {{ END }}
                {{ IF us.status != 'PROGRESS' }}
                [
                    {
                        "text": "🗑 Удалить услугу",
                        "callback_data": "/delete {{ args.0 }}"
                    }
                ],
                {{ END }}
                [
                    {
                        "text": "🏠 Вернуться в меню",
                        "callback_data": "/menu"
                    }
                ]
            ]
        }
    }
}

<% CASE '/notifications_renewal' %>
{{ item = us.id(args.0) }}
{{ TEXT = BLOCK }}
<b>⏳ Напоминание о скором продлении услуги!</b>

<b>🔹 Название услуги:</b> <code>{{ item.name }}</code>
<b>🔹 ID услуги:</b> № <code>{{ item.user_service_id }}</code>
<b>📅 Дата продления:</b> <i>{{ item.renewal_date }}</i>

<b>💰 Сумма к оплате:</b> <i>{{ user.pays.forecast('active', 1).total }}₽</i>

<b>❗ Пожалуйста, пополните баланс до даты продления, чтобы избежать блокировки услуги.</b> 💳

<b>👉 Для пополнения перейдите по ссылке:</b> <a href="{{ subscription_url }}">Пополнить баланс</a>
{{ END }}

{
    "sendMessage": {
        "text": "{{ TEXT.replace('\n','\n') }}\n",
        "parse_mode": "HTML",
        "reply_markup": {
            "inline_keyboard": [
                [
                    {
                        "text": "🏠 Вернуться в меню",
                        "callback_data": "/menu"
                    },
                    [
                        {
                            "text": "💳 Пополнить баланс",
                            "url": "/balance {{ args.1 }}"
                        }
                    ]
                ]
            ]
        }
    }
}

<% CASE '/notifications_payment' %>
{{ item = us.id(args.0) }}
{{ TEXT = BLOCK }}
<b>💸 Успешная оплата!</b>

<b>🔹 Название услуги:</b> <code>{{ item.name }}</code>
<b>🔹 ID услуги:</b> № <code>{{ item.user_service_id }}</code>
<b>📅 Дата оплаты:</b> <i>{{ payment_date }}</i>

<b>💰 Сумма оплаты:</b> <i>{{ payment_amount }}₽</i>

<b>Спасибо, что остаетесь с нами!</b> 🙌
{{ END }}

{
    "sendMessage": {
        "text": "{{ TEXT.replace('\n','\n') }}\n",
        "parse_mode": "HTML",
        "reply_markup": {
            "inline_keyboard": [
                [
                    {
                        "text": "🏠 Вернуться в меню",
                        "callback_data": "/menu"
                    }
                ]
            ]
        }
    }
}

<% CASE '/notifications_registered' %>
{{ item = us.id(args.0) }}
{{ TEXT = BLOCK }}
<b>🎉 Добро пожаловать!</b>

<b>🔹 Ваш аккаунт успешно зарегистрирован.</b>
<b>🔹 ID пользователя:</b> № <code>{{ item.user_id }}</code>

<b>Мы рады, что вы выбрали нас!</b> 🚀
{{ END }}

{
    "sendMessage": {
        "text": "{{ TEXT.replace('\n','\n') }}\n",
        "parse_mode": "HTML",
        "reply_markup": {
            "inline_keyboard": [
                [
                    {
                        "text": "🏠 Вернуться в меню",
                        "callback_data": "/menu"
                    }
                ]
            ]
        }
    }
}

<% CASE '/notifications_remove' %>
{{ item = us.id(args.0) }}
{{ TEXT = BLOCK }}
<b>❌ Услуга удалена</b>

<b>🔹 Название услуги:</b> <code>{{ item.name }}</code>
<b>🔹 ID услуги:</b> № <code>{{ item.user_service_id }}</code>

<b>Спасибо, что пользовались нашими услугами!</b>
{{ END }}


{
    "sendMessage": {
        "text": "{{ TEXT.replace('\n','\n') }}\n",
        "parse_mode": "HTML",
        "reply_markup": {
            "inline_keyboard": [
                [
                    {
                        "text": "🏠 Вернуться в меню",
                        "callback_data": "/menu"
                    }
                ]
            ]
        }
    }
}

<% CASE '/notifications_prolongate' %>
{{ item = us.id(args.0) }}
{{ TEXT = BLOCK }}
<b>🔄 Срок действия услуги продлен!</b>

<b>🔹 Название услуги:</b> <code>{{ item.name }}</code>
<b>🔹 ID услуги:</b> № <code>{{ item.user_service_id }}</code>
<b>📅 Новый срок действия:</b> <i>{{ item.new_date }}</i>

<b>Спасибо, что остаетесь с нами!</b> 🙏
{{ END }}


{
    "sendMessage": {
        "text": "{{ TEXT.replace('\n','\n') }}\n",
        "parse_mode": "HTML",
        "reply_markup": {
            "inline_keyboard": [
                [
                    {
                        "text": "🏠 Вернуться в меню",
                        "callback_data": "/menu"
                    }
                ]
            ]
        }
    }
}

<% CASE '/notifications_changed' %>
{{ item = us.id(args.0) }}
{{ IF event_name == "CHANGED" }}
{{ TEXT = BLOCK }}
<b>✏️ Изменения внесены</b>

<b>🔹 Название услуги:</b> <code>{{ item.name }}</code>
<b>🔹 ID услуги:</b> № <code>{{ item.user_service_id }}</code>
<b>📅 Дата изменения:</b> <i>{{ change_date }}</i>

<b>Ваши данные были успешно обновлены!</b>
{{ END }}

{
    "sendMessage": {
        "text": "{{ TEXT.replace('\n','\n') }}\n",
        "parse_mode": "HTML",
        "reply_markup": {
            "inline_keyboard": [
                [
                    {
                        "text": "🏠 Вернуться в меню",
                        "callback_data": "/menu"
                    }
                ]
            ]
        }
    }
}

<% CASE '/notifications_bonus' %>
{{ item = us.id(args.0) }}
{{ TEXT = BLOCK }}
<b>🎁 Вы получили бонус!</b>

<b>🔹 Название услуги:</b> <code>{{ item.name }}</code>
<b>🔹 ID услуги:</b> № <code>{{ item.user_service_id }}</code>
<b>💰 Размер бонуса:</b> <i>{{ bonus_amount }}₽</i>

<b>Спасибо, что вы с нами!</b> 💖
{{ END }}

{
    "sendMessage": {
        "text": "{{ TEXT.replace('\n','\n') }}\n",
        "parse_mode": "HTML",
        "reply_markup": {
            "inline_keyboard": [
                [
                    {
                        "text": "🏠 Вернуться в меню",
                        "callback_data": "/menu"
                    }
                ]
            ]
        }
    }
}



<% CASE '/delete' %>
{{
  us = user.service.list_for_api('usi', args.0);
}}
{{ IF us.status != 'ACTIVE' }}
{
    "deleteMessage": { "message_id": {{ message.message_id }} }
},
{
    "sendMessage": {
        "text": "🤔 <b>Подтвердите удаление ключа #{{ args.0 }}. Ключ нельзя будет восстановить!</b>",
        "reply_markup": {
            "inline_keyboard": [
                [
                    {
                        "text": "🧨 ДА, УДАЛИТЬ! 🔥",
                        "callback_data": "user:keys:delete:confirm {{ args.0 }}"
                    }
                ],
                [
                    {
                        "text": "⇦ Назад",
                        "callback_data": "/list"
                    }
                ]
            ]
        }
    }
}
{{ ELSE }}
{
    "sendMessage": {
        "text": "❌ Невозможно удалить ключ #{{ args.0 }}, так как он активен.",
        "reply_markup": {
            "inline_keyboard": [
                [
                    {
                        "text": "⇦ Назад",
                        "callback_data": "/list"
                    }
                ]
            ]
        }
    }
}
{{ END }}

<% CASE 'user:keys:delete:confirm' %>
{
    "deleteMessage": { 
        "message_id": "{{ message.message_id }}" 
    }
},
{
    "shmServiceDelete": {
        "usi": "{{ args.0 }}",
        "callback_data": "/menu",
        "error": "ОШИБКА"
    }
},
{
    "answerCallbackQuery": {
        "callback_query_id": "{{ callback_query.id }}",
        "parse_mode": "HTML",
        "text": "✅ Ключ успешно удален!",
        "show_alert": true
    }
}



<% CASE '/referrals' %>
{{ # Попробуй так }}
{
    "deleteMessage": { "message_id": {{ message.message_id }} }
},
{{ TEXT = BLOCK }}
🤝 <b>Добро пожаловать в нашу реферальную программу!\n
Приглашено друзей: {{ user.referrals_count }}  \n
Доход от рефералов: {{ user.get_bonus }} ₽ \n</b>
Приглашайте друзей и получайте: <b>{{ config.billing.partner.income_percent }}% от каждого их платежа</b>.\n\n
🔗 <b>Ваша реферальная ссылка:</b>\n
<code>{{ config.setting_tgmy_bot.BotUrl }}?start={{ user.id }}</code>\n
Поделитесь ссылкой с друзьями!
{{ END }}
{
    "sendMessage": {
        "text": "{{ TEXT.replace('\n','\n') }}",
        "reply_markup": {
            "inline_keyboard": [
                [
                    {
                        "text": "📤 Поделиться ссылкой",
                        "switch_inline_query": "Присоединяйся к {{ config.company.name }} и зарабатывай с нами! 🛡 {{ config.setting_tgmy_bot.BotUrl }}?start={{ user.id }}"
                    }
                ],
                [
                    {
                        "text": "📤 Список приведеных",
                        "callback_data": "/ref_list"
                    },
                    {
                        "text": "❓ Как это работает?",
                        "callback_data": "/referral_help"
                    }
                ],
                [
                    {
                        "text": "🔙 Назад",
                        "callback_data": "/menu"
                    }
                ]
            ]
        }
    }
}

<% CASE '/ref_list' %>
{
    "deleteMessage": { "message_id": {{ message.message_id }} }
},

{{
    limit = 5;
    offset = (args.0 || 0);
    referralsArray = ref(user.list_for_api('admin', 1, 'limit', limit, 'offset', offset, 'filter',{"partner_id" = user.id}));
}}
{{ TEXT = BLOCK }}
📃 <b>Список приглашенных пользователей</b>

Всего приглашено: {{ user.referrals_count }}
{{ END }}
{
    "sendMessage": {
        "text": "{{ TEXT.replace('\n','\n') }}",
         "reply_markup": {
            "inline_keyboard": [
			{{ FOR item in referralsArray }}
				[
                    {
                        "text": "👤 {{ item.full_name }} 🌟",
                        "callback_data": "/ref_info {{ item.id }}"
                    }
                ],
    {{ END }}
                [
                    {{ IF offset > 0 }}
                    {
                        "text": "⬅️ Назад",
                        "callback_data": "/ref_list {{ offset - limit }}"
                    },
                    {{ END }}
                    {{ IF referralsArray.size == limit }}
                    {
                        "text": "Ещё ➡️",
                        "callback_data": "/ref_list {{ offset + limit }}"
                    }
                    {{ END }}
                ],
				[
                    {
                        "text": "🔄 Обновить",
                        "callback_data": "/ref_list"
                    }
                ],
                [
                    {
                        "text": "🏠 Главное меню",
                        "callback_data": "/menu"
                    }
                ]
            ]
        }
    }
}

<% CASE '/ref_info' %>

{{
    ref_user = user.id(args.0);
}}
{{ TEXT = BLOCK }}
👤 <b>Информация о пользователе</b>

<b>Имя:</b> {{ ref_user.full_name }}
<b>ID:</b> {{ ref_user.id }}
<b>Дата регистрации:</b> {{ ref_user.created_at }}
<b>Статус:</b> {{ ref_user.status }}

{{ END }}
{
    "sendMessage": {
        "text": "{{ TEXT.replace('\n','\n') }}",
        "parse_mode": "HTML",
        "reply_markup": {
            "inline_keyboard": [
                [
                    {
                        "text": "⬅️ Назад к списку",
                        "callback_data": "/ref_list"
                    }
                ],
                [
                    {
                        "text": "🏠 Главное меню",
                        "callback_data": "/menu"
                    }
                ]
            ]
        }
    }
}

<% CASE '/referral_help' %>
{
    "deleteMessage": { "message_id": {{ message.message_id }} }
},
{
    "sendMessage": {
        "text": "🔍 <b>Как работает наша реферальная программа?</b>\n\nВ нашей программе вы можете зарабатывать, приглашая друзей! Каждый приглашённый человек получает уникальную ссылку, по которой он может зарегистрироваться и начать пользоваться нашими услугами.\n\n💸 <b>Что вам нужно:</b>\nВы получаете <b>{{ config.billing.partner.income_percent }}%</b> от каждого платежа, который сделает ваш реферал. Это отличный способ получить стабильный доход!\n\n🔗 <b>Как пригласить друга:</b>\n1. Скопируйте свою реферальную ссылку.\n2. Поделитесь ею с друзьями, коллегами или в социальных сетях.\n3. Когда ваш реферал сделает первый платёж, вы получите свою долю!\n\n💡 <b>Советы для увеличения дохода:</b>\n1. Разместите ссылку в соцсетях и мессенджерах.\n2. Расскажите о преимуществах нашего сервиса и бонусах для новых пользователей.\n\nЕсли возникнут вопросы, всегда можете обратиться в нашу службу поддержки.\n\n🔗 Ваша реферальная ссылка:\n<code>{{ config.setting_tgmy_bot.BotUrl }}?start={{ user.id }}</code>",
        "parse_mode": "HTML",
        "reply_markup": {
            "inline_keyboard": [
                [
                    {
                        "text": "🎯 Поделиться ссылкой",
                        "switch_inline_query": "Присоединяйся к {{ config.company.name }} и получай бонусы! 🛡 {{ config.setting_tgmy_bot.BotUrl }}?start={{ user.id }}"
                    }
                ],
                [
                    {
                        "text": "⬅️ Назад в меню",
                        "callback_data": "/menu"
                    }
                ]
            ]
        }
    }
}

<% CASE '/help' %>
{
    "deleteMessage": { "message_id": {{ message.message_id }} }
},
{
    "sendPhoto": {
        "photo": "{{ config.setting_tgmy_bot.logoUrl }}",
        "protect_content": "true",
        "parse_mode":"HTML",
        "caption": "<b>Сообщите Ваш ID: {{ user.id }} при обращении в поддержку!</b> \n Выберите инструкцию:",
        "reply_markup" : {
            "inline_keyboard": [
                [
                    {
                        "text": "📱 Инструкция для Android",
                        "callback_data": "/instructions_android"
                    }
                ],
                [
                    {
                        "text": "📱 Инструкция для iPhone",
                        "callback_data": "/instructions_iphone"
                    }
                ],
                [
                    {
                        "text": "Правила пользования, оплаты сервиса",
                        "web_app": { "url": "{{ config.setting_tgmy_bot.PolitikaUrl }}" }
                    }
                ],
                [
                    {
                        "text": "Чат поддержки",
                        "url": "{{ config.setting_tgmy_bot.supportUrl }}"
                    }
                ],
                [
                    {
                        "text": "⇦ Меню",
                        "callback_data": "/menu"
                    }
                ]
            ]
        }
    }
}

<% CASE ['/instructions_android'] %>
{
    "sendMessage": {
        "text": "🖥 <b>Полная инструкция по подключению Happ - Proxy Utility (Android)</b>\n\n<b>Шаг 1:</b>\n\n1️⃣ **Скачай приложение Happ - Proxy Utility** из [Google Play Store 📲](https://play.google.com/store/apps/details?id=com.happproxy).\n\n<pre><i>Фото: На экране будет кнопка «Установить» после перехода по ссылке.</i></pre>\n\n",
        "parse_mode": "HTML",
        "reply_markup": {
            "inline_keyboard": [
                [
                    {
                        "text": "Далее ➡️",
                        "callback_data": "instructions_android_step_2"
                    }
                ],
				[
                    {
                        "text": "⇦ Меню",
                        "callback_data": "/menu"
                    }
                ]
            ]
        }
    }
}
<% CASE ['instructions_android_step_2'] %>

{
    "sendPhoto": {
        "photo": "https://sun9-17.userapi.com/impg/YZHwJ5j41EDqgBrp9YtLzPVS39JoTIpEMWZCKw/IRAG_koCQDY.jpg?size=139x302&quality=95&sign=1465e9bec98d7ad7c14ce69bfb301b93&type=album",
        "caption": "Выполните все разрешения которые запросит приложение.",
        "parse_mode": "HTML",
        "reply_markup": {
            "inline_keyboard": [
                [
                    {
                        "text": "⬅️ Назад",
                        "callback_data": "/instructions_android"
                    },
                    {
                        "text": "Далее ➡️",
                        "callback_data": "instructions_android_step_3"
                    }
                ],
				[
                    {
                        "text": "⇦ Меню",
                        "callback_data": "/menu"
                    }
                ]
            ]
        }
    }
}
<% CASE ['instructions_android_step_3'] %>

{
    "sendPhoto": {
        "photo": "https://psv4.userapi.com/s/v1/d/gdiXPkKCascGKxt5oq18t-t2wyjNu_uBJdd9guB2jYiYgeU8MesLrgWNf6OVcPrEazBjij5XNQuqCWZt5_ouELSWeuKWinUBalJZZIhKRef49XnVeMYccg/Fotoram_io.jpg",
        "caption": "Вернитель в бота VPN > перейдите в ➡️ 🛡Список VPN ключей. ➡️ Выберите нужный ключ для подключения ➡️ Нажмите на кнопку Подключится ➡️ Далее нажмите на кнопку Ваш VPN ключ! и подтвердите добавление. Приятного пользования, Вы великолепны!  ",
        "parse_mode": "HTML",
        "reply_markup": {
            "inline_keyboard": [

				[
                    {
                        "text": "⇦ Меню",
                        "callback_data": "/menu"
                    }
                ]
            ]
        }
    }
}

<% CASE ['/instructions_iphone'] %>
{
    "sendMessage": {
        "text": "🖥 <b>Полная инструкция по подключению Happ - Proxy Utility (iPhone)</b>\n\n<b>Шаг 1:</b>\n\n1️⃣ **Скачай приложение Hiddify** из [App Store 📱](https://apps.apple.com/us/app/happ-proxy-utility/id6504287215).\n\n<pre><i>Фото: На экране будет кнопка «Установить» после перехода по ссылке.</i></pre>\n\n",
        "parse_mode": "HTML",
        "reply_markup": {
            "inline_keyboard": [
                [
                    {
                        "text": "Далее ➡️",
                        "callback_data": "instructions_iphone_step_2"
                    }
                ],
				[
                    {
                        "text": "⇦ Меню",
                        "callback_data": "/menu"
                    }
                ]
            ]
        }
    }
}
<% CASE ['instructions_iphone_step_2'] %>
{
    "sendPhoto": {
        "photo": "https://sun9-17.userapi.com/impg/YZHwJ5j41EDqgBrp9YtLzPVS39JoTIpEMWZCKw/IRAG_koCQDY.jpg?size=139x302&quality=95&sign=1465e9bec98d7ad7c14ce69bfb301b93&type=album",
        "caption": "Выполните все разрешения которые запросит приложение.",
        "parse_mode": "HTML",
        "reply_markup": {
            "inline_keyboard": [
                [
                    {
                        "text": "⬅️ Назад",
                        "callback_data": "/instructions_iphone"
                    },
                    {
                        "text": "Далее ➡️",
                        "callback_data": "instructions_iphone_step_3"
                    }
                ],
				[
                    {
                        "text": "⇦ Меню",
                        "callback_data": "/menu"
                    }
                ]
            ]
        }
    }
}
<% CASE ['instructions_iphone_step_3'] %>
{
    "sendPhoto": {
        "photo": "https://psv4.userapi.com/s/v1/d/gdiXPkKCascGKxt5oq18t-t2wyjNu_uBJdd9guB2jYiYgeU8MesLrgWNf6OVcPrEazBjij5XNQuqCWZt5_ouELSWeuKWinUBalJZZIhKRef49XnVeMYccg/Fotoram_io.jpg",
        "caption": "Вернитель в бота VPN > перейдите в ➡️ 🛡Список VPN ключей. ➡️ Выберите нужный ключ для подключения ➡️ Нажмите на кнопку Подключится ➡️ Далее нажмите на кнопку Ваш VPN ключ! и подтвердите добавление. Приятного пользования, Вы великолепны!  ",
        "parse_mode": "HTML",
        "reply_markup": {
            "inline_keyboard": [
                [
                    {
                        "text": "⬅️ Назад",
                        "callback_data": "instructions_iphone_step_2"
                    }
                ],
				[
                    {
                        "text": "⇦ Меню",
                        "callback_data": "/menu"
                    }
                ]
            ]
        }
    }
}

<% CASE '/show_mz_keys' %>
{
    "deleteMessage": { "message_id": {{ message.message_id }} }
},
{{ location = storage.read('name', 'vpn_mrzb_' _ args.0).location }}
{{ item = us.id(args.0) }}
{{ subscription_url = storage.read('name', 'vpn_mrzb_' _ args.0 _ location).subscription_url }}
{
    "sendPhoto": {
        "photo": "{{ config.setting_tgmy_bot.logoUrl }}",
        "protect_content": false,
        "parse_mode": "HTML",
        "caption": "🌐 <b>Ваши VPN ключи и подписка:</b>\n\n🔗 <b>Ссылка на подписку:</b>\n\n<code>{{ subscription_url }}</code>\n\n💡 <i>Скопируйте этот URL для настройки VPN-соединения на вашем устройстве.</i>\n\n🔐 <b>Выберите ключ для получения:</b>",
        "reply_markup": {
            "inline_keyboard": [
                [
                    {
                        "text": "🔑 Показать 'TCP' ",
                        "callback_data": "/trojan_key {{ args.0 }}"
                    },
                    {
                        "text": "🔑 Показать 'UDP' ",
                        "callback_data": "/vless_key {{ args.0 }}"
                    }
                ],
                [
                    {
                        "text": "⬅️ Назад к услугам",
                        "callback_data": "/service {{ args.0 }}"
                    }
                ]
            ]
        }
    }
}

<% CASE '/vless_key' %>
{
    "deleteMessage": { "message_id": {{ message.message_id }} }
},
{{ vless_tcp = storage.read('name', 'vpn_mrzb_' _ args.0).links.grep('^vless:').first }}
{
    "printQrCode": {
        "data": "{{ vless_tcp }}",
        "parameters": {
            "parse_mode": "HTML",
            "caption": "✅ <b>Ваш VLESS TCP ключ успешно сгенерирован!</b>\n\n📥 <i>QR-код отправлен. Используйте его для быстрой настройки VPN-соединения.</i>"
        }
    }
},
{
    "sendMessage": {
        "text": "🔑 <b>Ваш VLESS TCP ключ</b>\n\n🌐 <b>Протокол:</b> VLESS TCP\n\n🗝️ <b>Ключ:</b> <code>{{ vless_tcp }}</code>\n\n📲 <i>Сканируйте QR-код для мгновенной настройки VPN на вашем устройстве.</i>\n\n💡 <b>Совет:</b> Сохраните ключ в надежном месте для дальнейшего использования.",
        "reply_markup": {
            "inline_keyboard": [
                [
                    {
                        "text": "🔄 Изменить тариф",
                        "callback_data": "/selectservice {{ args.0 }}"
                    }
                ],
                [
                    {
                        "text": "⬅️ Назад к ключам",
                        "callback_data": "/show_mz_keys {{ args.0 }}"
                    }
                ]
            ]
        }
    }
}

<% CASE '/trojan_key' %>
{
    "deleteMessage": { "message_id": {{ message.message_id }} }
},
{{ trojan = storage.read('name', 'vpn_mrzb_' _ args.0).links.grep('^trojan:').first }}
{
    "printQrCode": {
        "data": "{{ trojan }}",
        "parameters": {
            "parse_mode": "HTML",
            "caption": "✅ <b>Ваш Trojan TCP ключ успешно сгенерирован!</b>\n\n🔒 <i>QR-код отправлен для безопасного подключения. Используйте его для быстрого и надежного соединения.</i>\n\n💡 <b>Не забудьте сохранить ключ в надежном месте.</b>",
            "size": 600
        }
    }
},
{
    "sendMessage": {
        "text": "🔑 <b>Ваш Trojan TCP ключ</b>\n\n<b>Протокол:</b> Trojan TCP\n\n🗝️ <b>Ключ:</b> <code>{{ trojan }}</code>\n\n📲 <i>Сканируйте QR-код для быстрой настройки VPN на вашем устройстве.</i>\n\n💡 <b>Совет:</b> Сохраните ключ в надежном месте, чтобы не потерять доступ к VPN-соединению.\n\n🔒 <b>Что такое Trojan?</b>\nTrojan — это безопасный и быстрый протокол, идеально подходящий для обхода блокировок и защиты конфиденциальности. Особенно эффективен в странах с ограниченным доступом к интернет-ресурсам.",
        "reply_markup": {
            "inline_keyboard": [
                [
                    {
                        "text": "⬅️ Назад к ключам",
                        "callback_data": "/show_mz_keys {{ args.0 }}"
                    }
                ]
            ]
        }
    }
}

<% CASE '/list_android_tv' %>
{
    "deleteMessage": { "message_id": {{ message.message_id }} }
},
{
    "sendMessage": {
        "text": "🔑  Выбрать и заказать Ключ",
        "reply_markup" : {
            "inline_keyboard": [
                {{ FOR item IN ref( user.services.list_for_api( 'category', 'vpn-mz-tv' ) ) }}
                {{ SWITCH item.status }}
                  {{ CASE 'ACTIVE' }}
                  {{ icon = '✅' }}
                  {{ status = 'Работает' }}
                  {{ CASE 'BLOCK' }}
                  {{ icon = '❌' }}
                  {{ status = 'Заблокирована' }}
                  {{ CASE 'NOT PAID' }}
                  {{ icon = '💰' }}
                  {{ status = 'Ожидает оплаты' }}
                  {{ CASE }}
                  {{ icon = '⏳' }}
                  {{ status = 'Обработка' }}
                {{ END }}
                [
                    {
                        "text": "{{ icon }} {{ status }} - {{ item.name }}. {{ user.full_name }} - ({{ item.user_service_id }})",
                        {{ IF item.category != 'vpn-mz-tv' }}
                        "callback_data": "/service {{ item.user_service_id }}"
                        {{ ELSIF item.category == 'vpn-mz-tv' }}
                        "callback_data": "/setup_android {{ item.user_service_id }}"
                        {{ END }}
                    }
                ],
                {{ END }}
                [
                    {
                        "text": "🛒 Заказать Ключ",
                        "callback_data": "/pricelist_android_tv"
                    }
                ],
                [
                    {
                        "text": "⇦ Назад",
                        "callback_data": "/menu"
                    }
                ]
            ]
        }
    }
}

<% CASE [ '/setup_android', '/setup_android_list' ] %>
{{ us = user.services.list_for_api( 'usi', args.0 ) }}
{
    "editMessageText": {
        "message_id": {{ message.message_id }},
{{ TEXT = BLOCK }}
🔒 Перед подключением Android TV ознакомьтесь с инструкцией 📖

🎬 Подключение Android TV за 5 шагов:

1️⃣ Ознакомьтесь с инструкцией 📖
Перед подключением устройства обязательно ознакомьтесь с руководством. Это поможет избежать ошибок и настроить всё правильно с первого раза.

2️⃣ Получите персональную ссылку 🔑
Откройте браузер на вашем Android TV и введите вашу персональную ссылку. Это гарантирует правильную настройку устройства.
📍 Ваша персональная ссылка:
<b>{{ config.shmcustomlab.tv_domain }}/{{ us.settings.pin }}</b>

3️⃣ Проверьте подключение 🛠️
Убедитесь, что ваш Android TV подключён к сети Wi-Fi и что сигнал стабилен для корректной работы.

4️⃣ Перезагрузите устройство 🔄
После ввода ссылки и завершения настроек перезагрузите Android TV, чтобы изменения вступили в силу.

5️⃣ Готово! 🎉
Теперь наслаждайтесь всеми возможностями вашего Android TV. Приятного использования! 🌟
{{ END }}          
        "text": "{{ TEXT.replace('\n','\n') }}",
        "parse_mode":"HTML",
        "reply_markup" : {
            "inline_keyboard": [
                {{ IF us.status == 'ACTIVE' }}
                [
                    {
                        "text": "Инструкция по подключению",
                        "url": "https://telegra.ph/Podklyuchenie-Android-TV-za-5-shagov-01-22"
                    }
                ],
                {{ END }}
                {{ IF us.status == 'NOT PAID' || us.status == 'BLOCK' }}
                [
                    {
                        "text": "💰 Оплатить {{ user.pays.forecast('blocked',1).total }} ₽",
                        "web_app": {
                        "url": "{{ config.api.url }}/shm/v1/public/tg_payments_webapp?format=html&user_id={{ user.id }}"
                        }
                    }
                ],
                {{ END }}
                [
                    {
                        "text": "Чат с поддержкой",
                        "url": "{{ config.shmcustomlab.support }}"
                    }
                ],                
                [
                    {
                        "text": "Назад",
                        "callback_data": "/list_android_tv"
                    }
                ]
            ]
        }
    }
}

<% CASE '/topup' %>
{
    "sendMessage": {
        "message_id": {{ message.message_id }},
        "parse_mode": "HTML",
        "disable_web_page_preview": true,
        "text": "Для пополнения баланса, пожалуйста, воспользуйтесь одним из предложенных способов оплаты:\n\n<a href=\"https://www.tinkoff.ru/rm/\"><b>Тинькофф</b></a>\n\nЕсли вы используете другой банк, выполните перевод по номеру телефона:\n<code>+7000000000</code> Тинькофф (Павел П.)\n\nПосле оплаты, сохраните скриншот платежа и нажмите кнопку <b>\"Я оплатил\"</b>.\n\nНеобходимо оплатить: <b>{{ user.pays.forecast('blocked',1).total }}</b> рублей.",
        "reply_markup": {
            "inline_keyboard": [
                [
                    {
                        "text": "Я оплатил",
                        "callback_data": "/sendreceipt {{ amount }}"
                    }
                ],
                [
                    {
                        "text": "Назад",
                        "callback_data": "/menu"
                    }
                ]
            ]
        }
    }
}
<% CASE '/sendreceipt' %>
{
    "deleteMessage": { "message_id": {{ message.message_id }} }
},
{
    "sendMessage": {
        "text": "<b>Отправьте квитанцию об оплате</b>",
        "parse_mode": "HTML",
        "reply_markup": {
            "force_reply": true
        }
    }
}

<% CASE 'admin:menu' %>
{{ TEXT = BLOCK }}
〠 <b>Меню {{ role = (user.settings.role == 'admin' ? 'администратора' : 'модератора'); role; }}</b>

⭕️ Будьте осторожны с выбором действий!
{{ END }}
{
    "sendMessage": {
        "message_id": {{ message.message_id }},
        "parse_mode": "HTML",
        "text": "{{ TEXT.replace('\n','\n') }}",
        "reply_markup": {
            "inline_keyboard": [
                [
                    {
                        "text": "👥 Управление пользователями",
                        "callback_data": "admin:users:list"
                    },
                    {
                        "text": "🏠 Главное меню",
                        "callback_data": "/menu"
                    }
                ],
                {{ IF user.settings.role == 'admin' || (user.settings.role == 'moderator' && user.settings.moderate.settings == 1 )}}
                [
                    {
                        "text": "⚙️ Настройки бота",
                        "callback_data": "admin:settings"
                    }
                ],
                {{ END }}
                [
                    {
                        "text": "🏠 Главное меню",
                        "callback_data": "/menu"
                    }
                ]
            ]
        }
    }
}

<% CASE 'admin:settings' %>
{{
    # Check for admin or moderator rights
    PROCESS checkAdminRights;
    # Check right for change settings
    checkModeratorRights(right="settings");
}}

{{ TEXT = BLOCK }}
<b>Конфигурация бота</b>

Запретить оформления новых ключей, если есть неоплаченные: {{ notPaidStatus = (checkNotPaidServices == 0 ? '⭕️ Выключено' : '🟢 Включено'); notPaidStatus; }}

Тип сообщений: {{ messageTypeStatus = (defaultMessageType == 'editMessageText' ? '✏️ Редактирование' : '🆕 Новое сообщение'); messageTypeStatus; }}
{{ END }}

{
    "sendMessage": {
        "parse_mode": "HTML",
        "text": "{{ TEXT.replace('\n','\n') }}",
        "reply_markup": {
            "inline_keyboard": [
                [
                    {
                        "text": "Изменить запрет оформления",
                        "callback_data": "admin:settings:change notpaid"
                    }
                ],
                [
                    {
                        "text": "Изменить тип сообщений",
                        "callback_data": "admin:settings:change msg"
                    }
                ],
                [
                    {
                        "text": "👨‍💻 Меню {{ menuRole = (user.settings.role == 'admin' ? 'администратора' : 'модератора'); menuRole; }}",
                        "callback_data": "admin:menu"
                    },
                    {
                        "text": "🏠 Главное меню",
                        "callback_data": "/menu"
                    }
                ]
            ]
        }
    }
}

<% CASE 'admin:settings:change' %>
{{
    # Check for admin or moderator rights
    PROCESS checkAdminRights;

    IF args.0 == 'notpaid'; 
        IF checkNotPaidServices == 0;
            ret = user.id(1).storage.save('bot_configuration', 'checkNotPaidServices' => 1, 'messageType' => defaultMessageType, 'menuCmd' => mainMenuCmd );
        ELSIF checkNotPaidServices == 1;
            ret = user.id(1).storage.save('bot_configuration', 'checkNotPaidServices' => 0, 'messageType' => defaultMessageType, 'menuCmd' => mainMenuCmd );
        END;
        sendAlert(errtext="✅ Запрет оформления новых ключей изменен!", redirect="admin:settings");
    
    ELSIF args.0 == 'msg';
        IF defaultMessageType == 'sendMessage';
            ret = user.id(1).storage.save('bot_configuration', 'checkNotPaidServices' => checkNotPaidServices, 'messageType' => 'editMessageText', 'menuCmd' => 'menu' );
        ELSIF defaultMessageType == 'editMessageText';
            ret = user.id(1).storage.save('bot_configuration', 'checkNotPaidServices' => checkNotPaidServices, 'messageType' => 'sendMessage', 'menuCmd' => 'start' );
        END;
        sendAlert(errtext="✅ Тип сообщений изменен!", redirect="admin:settings");
    END;
}}


<% CASE 'admin:users:list' %>
{{
    limit = 7;
    offset = (args.0 || 0);
    users = ref(user.list_for_api('admin', 1, 'limit', limit, 'offset', offset, 'filter',{"gid" = 0}));
    getCountUsers = ref(user.list_for_api('admin', 1, 'limit', 10000, filter, {"gid" = 0})).size;
}}
{{ TEXT = BLOCK }}
👨‍💻 Пользователи

👤 Всего пользователей: {{ getCountUsers - 1 }}
{{ END }}
{
    "sendMessage": {
        "text": "{{ TEXT.replace('\n','\n') }}",
        "reply_markup": {
            "inline_keyboard": [
			[{ "text": "🔎 Найти по ID", "callback_data": "admin:users:search" }],
                {{ FOR item IN users }}
                    {{ status = (item.block == 0 ? "🟢" : "🔴") }}
                    [
                        {
                            "text": "{{ status _' '_ item.full_name.replace('"', '\"')  }} ({{ item.user_id _'-'_ item.login }})",
                            "callback_data": "admin:users:id {{ item.user_id _' '_ offset }}"
                        }
                    ],
                {{ END }}
                {{ IF users.size == limit || offset > 0 }}
                    [
                        {{ IF offset > 0 }}
                            {
                                "text": "⬅️ Назад",
                                "callback_data": "admin:users:list {{ offset - limit }}"
                            },
                        {{ END }}
                        {{ IF users.size == limit }}
                            {
                                "text": "Ещё ➡️",
                                "callback_data": "admin:users:list {{ limit + offset }}"
                            }
                        {{ END }}
                    ],
                {{ END }}
                [
                    {
                        "text": "👨‍💻 Меню {{ menuRole = (user.settings.role == 'admin' ? 'администратора' : 'модератора'); menuRole; }}",
                        "callback_data": "admin:menu"
                    },
                    {
                        "text": "🏠 Главное меню",
                        "callback_data": "/menu"
                    }
                ]
            ]
        }
    }
}

<% CASE 'admin:users:id' %>
{{ IF user.settings.role == 'moderator' || user.settings.role == 'admin'; }}
{{ user = user.switch(args.0) }}
{{
    userData = user.id(args.0);
    userPartner = user.id(userData.partner_id);
    userServices = ref(userData.services.list_for_api('category', '%'));
    offset = args.1;
}}

{{ TEXT = BLOCK }}
👤 <b>Информация о пользователе</b>

Статус: {{ userStatus = (userData.block == 0 ? "🟢 Активен" : "🔴 Заблокирован"); userStatus; }}

Имя: {{ userData.full_name.replace('"', '\"') }}
ID: {{ userData.user_id }}
Telegram: {{ userData.settings.telegram.login }}
Логин: {{ userData.login }}

Дата регистрации: {{ userData.created }}
Дата последнего входа: {{ userData.last_login }}
Кто пригласил: {{ userPartner ? userPartner.full_name + " - " + userPartner.login : "❌ Нет данных" }}

Баланс: {{ userData.balance }} руб.  
Бонусы: {{ userData.get_bonus }} руб.  
Скидка: {{ userData.discount }}

Кол-во подписок: {{ userServices.size }}

{{ END }}

{
    "sendMessage": {
        "parse_mode": "HTML",
        "text": "{{ TEXT.replace('\n','\n') }}",
        "reply_markup": {
            "inline_keyboard": [
                [
                    {
                        "text": "🔐 Управление подписками",
                        "callback_data": "admin:users:id:subs {{ userData.user_id _' '_ offset }}"
                    }
                ],
                [
                    {
                        "text": "💸 Управление платежами",
                        "callback_data": "admin:users:id:pays {{ userData.user_id }}"
                    }
                ],
                [
                    {
                        "text": "🎁 Управление бонусами",
                        "callback_data": "admin:users:id:bonuses {{ userData.user_id }}"
                    }
                ],
				[
                    {
                        "text": "✉️ Написать пользователю 💬",
                        "callback_data": "admin:user:msg {{ user.settings.telegram.chat_id }}"
                    }
                ],
                [
                    {
                        "text": "{{ status = (userData.block == 0 ? "🔴 Заблокировать" : "🟢 Активировать"); status; }}",
                        "callback_data": "admin:users:block {{ userData.user_id }}"
                    }
                ],
                [
                    {
                        "text": "⬅️ Назад",
                        "callback_data": "admin:users:list {{ args.1 }}"
                    }
                ],
                [
                    {
                        "text": "👨‍💻 Меню {{ menuRole = (user.settings.role == 'admin' ? 'администратора' : 'модератора'); menuRole; }}",
                        "callback_data": "admin:menu"
                    },
                    {
                        "text": "🏠 Главное меню",
                        "callback_data": "/menu"
                    }
                ]
            ]
        }
    }
}
{{ END }}

<% CASE 'admin:user:msg' %>
{
    "sendMessage": {
        "text": "✉️ Введите сообщение для пользователя #{{ args.0 }}#",
        "reply_markup": {
            "force_reply": true
        }
    }
}

<% CASE 'admin:users:block' %>
{{
    # Check for admin or moderator rights
    PROCESS checkAdminRights;
    # Check right for change settings
    checkModeratorRights(right="blockUser");

    # Variables
    userData = user.id(args.0);
    name = userData.full_name.replace('"', '\"');
    retcode = (userData.block == 1 ? "0" : "1");
    ret = userData.set(block = retcode);
    status = (userData.block == 1 ? "🔴 заблокирован" : "🟢 активирован");

    sendAlert(errtext="✅ Пользователь $name ($userData.user_id) $status", redirect="admin:users:id $userData.user_id");
}}

<% CASE 'admin:users:id:subs' %>
{{
    # Check for admin or moderator rights
    PROCESS checkAdminRights;
    # Check right for change settings
    checkModeratorRights(right="listSubs");
}}
{{
    limit = 7;
    last_offset = (args.1 || 0);
    offset = (args.2 || 0);
    userData = user.id(args.0);
    userServices = ref(userData.services.list_for_api('limit', limit, 'offset', offset));
}}
{{ TEXT = BLOCK }}
🔐 Управление подписками

Имя: {{ userData.full_name.replace('"', '\"')  }}
ID: {{ userData.user_id }}
Telegram: {{ userData.settings.telegram.login }}
Логин: {{ userData.login }}

{{ IF userServices.size <= 0}}
<b>У пользователя нет подписок!</b>
{{ END }}
{{ END }}
{
    "editMessageText": {
        "message_id": {{ message.message_id }},
        "parse_mode": "HTML",
        "text": "{{ TEXT.replace('\n','\n') }}",
        "reply_markup": {
            "inline_keyboard": [
                {{ FOR item in userServices }}
                    {{ status = (item.status == 'ACTIVE' ? "🟢" : "🔴") }}
                    [
                        {
                            "text": "{{ status; item.user_service_id _' - '_ item.name  }}",
                            "callback_data": "admin:subs:id {{ item.user_service_id _ ' ' _ item.user_id }}"
                        }
                    ],
                {{ END }}

                {{ IF userServices.size == limit }}
                    [
                        {
                            "text": "Ещё ➡️",
                            "callback_data": "admin:users:list {{ limit + offset }}"
                        }
                    ],
                {{ END }}

                {{ IF offset > 0 }}
                    [
                        {
                            "text": "⬅️ Назад",
                            "callback_data": "admin:users:list {{ offset - limit }}"
                        }
                    ],
                {{ END }}

                [
                    {
                        "text": "➕ Добавить услугу",
                        "callback_data": "admin:subs:add {{ userData.user_id }}"
                    }
                ],
                [
                    {
                        "text": "➕ Добавить услугу (бесплатно)",
                        "callback_data": "admin:subs:add:free {{ userData.user_id }}"
                    }
                ],
                [
                    {
                        "text": "⬅️ Информация о пользователе",
                        "callback_data": "admin:users:id {{ userData.user_id _' '_ last_offset }}"
                    }
                ],
                [
                    {
                        "text": "👨‍💻 Меню {{ menuRole = (user.settings.role == 'admin' ? 'администратора' : 'модератора'); menuRole }}",
                        "callback_data": "admin:menu"
                    }
                ]
            ]
        }
    }
}

<% CASE ['admin:users:id:subs'] %>
{{ IF user.settings.role == 'moderator' || user.settings.role == 'admin' }}
{{
    limit = 7;
    last_offset = (args.1 || 0);
    offset = (args.2 || 0);
    userData = user.id(args.0);
    userServices = ref(userData.services.list_for_api('limit', limit, 'offset', offset));
}}

{{ TEXT = BLOCK }}
🔐 <b>Управление подписками</b>

👤 Имя: {{ userData.full_name.replace('"', '\"')  }}
🆔 ID: {{ userData.user_id }}  
📱 Telegram: {{ userData.settings.telegram.login }}
🔑 Логин: {{ userData.login }}  

{{ IF userServices.size <= 0 }}
<b>У пользователя нет подписок!</b>
{{ END }}
{{ END }}

{
    "editMessageText": {
        "message_id": {{ message.message_id }},
        "parse_mode": "HTML",
        "text": "{{ TEXT.replace('\n','\n') }}",
        "reply_markup": {
            "inline_keyboard": [
                {{ FOR item in userServices }}
                {{ status = (item.status == 'ACTIVE' ? "🟢" : "🔴") }}
                [
                    {
                        "text": "{{ status }} {{ item.user_service_id }} - {{ item.name }}",
                        "callback_data": "admin:subs:id {{ item.user_service_id _ ' ' _ item.user_id }}"
                    }
                ],
                {{ END }}

                {{ IF userServices.size == limit }}
                [
                    {
                        "text": "➡️ Ещё",
                        "callback_data": "admin:users:list {{ limit + offset }}"
                    }
                ],
                {{ END }}

                {{ IF offset > 0 }}
                [
                    {
                        "text": "⬅️ Назад",
                        "callback_data": "admin:users:list {{ offset - limit }}"
                    }
                ],
                {{ END }}

                [
                    {
                        "text": "➕ Добавить услугу",
                        "callback_data": "admin:subs:add {{ userData.user_id }}"
                    }
                ],
                [
                    {
                        "text": "➕ Добавить услугу (бесплатно)",
                        "callback_data": "admin:subs:add:free {{ userData.user_id }}"
                    }
                ],
                [
                    {
                        "text": "⬅️ Информация о пользователе",
                        "callback_data": "admin:users:id {{ userData.user_id _' '_ last_offset }}"
                    }
                ],
                [
                    {
                        "text": "👨‍💻 Меню {{ menuRole = (user.settings.role == 'admin' ? 'администратора' : 'модератора'); menuRole; }}",
                        "callback_data": "admin:menu"
                    }
                ]
            ]
        }
    }
}
{{ END }}

<% CASE 'admin:subs:add' %>
{{
    # Check for admin or moderator rights
    PROCESS checkAdminRights;
    # Check right for change settings
    checkModeratorRights(right="addSubs");
}}
{{
    # Variables
    userData = user.id(args.0);
    servicesArray = ref(service.list_for_api).nsort('service_id');
}}
{{ TEXT = BLOCK }}
➕ Выберите услугу для создания пользователю {{ userData.full_name.replace('"', '\"')  }} ({{ userData.user_id }})
{{ END }}

{
    "editMessageText": {
        "message_id": {{ message.message_id }},
        "parse_mode": "HTML",
        "text": "{{ TEXT.replace('\n','\n') }}",
        "reply_markup": {
            "inline_keyboard": [
                {{ FOR item in servicesArray }}
                [
                    {
                        "text": "{{ item.name _' '_ item.descr }} - {{ item.cost }} ₽",
                        "callback_data": "admin:subs:add:confirm {{ userData.user_id _' '_ item.service_id }}"
                    }
                ],
                {{ END }}

                [
                    {
                        "text": "⬅️ Назад",
                         "callback_data": "admin:users:id:subs {{ userData.user_id _' '_ args.1 }}"
                    }
                ],
                [
                    {
                        "text": "⬅️ Информация о пользователе",
                       "callback_data": "admin:users:id {{ userData.user_id _' '_ last_offset }}"
                    }
                ]
            ]
        }
    }
}

<% CASE 'admin:subs:add:free' %>
{{
    # Check for admin or moderator rights
    PROCESS checkAdminRights;
    # Check right for change settings
    checkModeratorRights(right="addFreeSubs");
}}
{{
    # Variables
    userData = user.id(args.0);
    servicesArray = ref(service.list_for_api).nsort('service_id');
}}
{{ TEXT = BLOCK }}
➕ Выберите услугу с 0 стоимостью для создания пользователю {{ userData.full_name.replace('"', '\"')  }} ({{ userData.user_id }})
{{ END }}

{
    "editMessageText": {
        "message_id": {{ message.message_id }},
        "parse_mode": "HTML",
        "text": "{{ TEXT.replace('\n','\n') }}",
        "reply_markup": {
            "inline_keyboard": [
    {{ FOR item in servicesArray }}
        [
            {
                "text": "{{ item.name _' '_ item.descr }} - {{ item.cost }} ₽",
                "callback_data": "admin:subs:add:confirm {{ userData.user_id _' '_ item.service_id _' free' }}"
            }
        ],
    {{ END }}
    [
        {
            "text": "⬅️ Назад",
            "callback_data": "admin:users:id:subs {{ userData.user_id _' '_ args.1 }}"
        }
    ],
    [
        {
            "text": "⬅️ Информация о пользователе",
            "callback_data": "admin:users:id {{ userData.user_id _' '_ last_offset }}"
        }
    ]
            ]
        }
    }
}


<% CASE 'admin:subs:add:confirm' %>
{{ PROCESS checkAdminRights }}
{{
    userData = user.id(args.0);
    createService = service.id(args.1);
    user = user.switch(userData.user_id);
    name = userData.full_name.replace('"', '\"');

    IF args.2 == 'free';
        ret = userData.us.create('service_id' = createService.service_id, 'cost' = 0, 'check_allow_to_order' = 0);
    ELSE;
        ret = userData.us.create('service_id' = createService.service_id, 'check_allow_to_order' = 0);
    END;

    sendAlert(errtext="✅ Подписка $createService.name успешно добавлена пользователю $name ($userData.user_id)", redirect="admin:users:id:subs $userData.user_id");
}}

<% CASE '/admusermsg' %>
{
"sendMessage": {
        "text": "#{{ args.0 }}#\nВведите сообщение для пользователя",
        "reply_markup": {
            "force_reply": true
        }
    }
}

<% CASE 'admin:subs:id' %>
{{
    # Check for admin or moderator rights
    PROCESS checkAdminRights;
    # Check right for change settings
    checkModeratorRights(right="listSubs");
}}
{{
    # Arguments:
        # 0 - ID of user service id 
        # 1 - ID of user
    # Variables:
    USE date;
    userData = user.id(args.1);
    userService = userData.us.id(args.0);
    userServiceData = service.id(userService.service_id);
    userServiceNext = service.id(userService.next);
    userSubUrl = (userData.storage.read('name', 'vpn_mrzb_'_ userService.user_service_id).subscription_url || "https://notfound.com");
    subData = http.get(userSubUrl _'/info');
}}
{{ TEXT = BLOCK }}
🔐 Подписка {{ userServiceData.name }} пользователя {{ userData.full_name.replace('"', '\"') }} ({{ userData.user_id }})

ID: {{ userService.user_service_id }}
ID списания: {{ userService.withdraw_id }}
Статус: {{ userService.status }}
Создана: {{ userService.created }}
Заканчивается: {{ userService.expire }}
Следующий тариф: {{ userServiceNext.name }}

Последний онлайн: {{ subData.online_at ? date.format(subData.online_at, '%d.%m.%Y %R') : 'нет информации' }}

{{ END }}

{
    "editMessageText": {
        "message_id": {{ message.message_id }},
        "parse_mode": "HTML",
        "text": "{{ TEXT.replace('\n','\n') }}",
        "reply_markup": {
            "inline_keyboard": [
                [
                    {
                        "text": "🔗 Подписка {{ userService.user_service_id }} - {{ userServiceData.name }}",
                        "web_app": {
                            "url": "{{ userSubUrl }}"
                        }
                    }
                ],
                {{ IF userService.status == 'ACTIVE' || userService.status == 'BLOCK' }}
                    [
                        {
                            "text": "{{ status = (userService.status == 'ACTIVE' ? "🔴 Заблокировать" : "🟢 Активировать"); status; }}",
                            "callback_data": "admin:subs:change:status {{ userService.user_service_id }}"
                        }
                    ],
                {{ ELSIF userService.status == 'PROGRESS' }}
                    [
                        {
                            "text": "⏳ Ожидание (обновите)",
                            "callback_data": "admin:subs:id {{ userService.user_service_id }}"
                        }
                    ],
                {{ END }}
                {{ IF userService.status == 'BLOCK' || userService.status == 'NOT PAID' }}
                    [
                        {
                            "text": "❌ Удалить подписку",
                            "callback_data": "admin:subs:delete {{ userService.user_service_id }}"
                        }
                    ],
                {{ END }}
                [
                    {
                        "text": "🫰 Информация о списании",
                        "callback_data": "admin:withdraws:id {{ userService.withdraw_id }}"
                    }
                ],
                [
                    {
                        "text": "⎘ Сменить текущ. тариф",
                        "callback_data": "admin:subs:change:current {{ userService.user_service_id }}"
                    }
                ],
                [
                    {
                        "text": "⎘ Сменить след. тариф",
                        "callback_data": "admin:subs:change:next {{ userService.user_service_id }}"
                    }
                ],
                [
                    {
                        "text": "⬅️ Назад",
                        "callback_data": "admin:users:id:subs {{ userData.user_id }}"
                    }
                ],
                [
                    {
                        "text": "👨‍💻 Меню {{ menuRole = (user.settings.role == 'admin' ? 'администратора' : 'модератора'); menuRole; }}",
                        "callback_data": "admin:menu"
                    },
                    {
                        "text": "🏠 Главное меню",
                        "callback_data": "/menu"
                    }
                ]
            ]
        }
    }
}

<% CASE 'admin:subs:change:current' %>
{{
    # Check for admin or moderator rights
    PROCESS checkAdminRights;
    # Check right for change settings
    checkModeratorRights(right="changeSubs");
}}
{{
    userService = ref(us.list_for_api('admin', 1, 'filter', {"user_service_id" = args.0})).first;
    userData = user.id(userService.user_id);
    userServiceData = service.id(userService.service_id);
}}
{{ TEXT = BLOCK }}
⎘ Выберите тариф на изменение для подписки {{ userServiceData.name }} пользователя {{ userData.full_name.replace('"', '\"')  }} ({{ userData.user_id }})

{{ END }}

{
    "editMessageText": {
        "message_id": {{ message.message_id }},
        "parse_mode": "HTML",
        "text": "{{ TEXT.replace('\n','\n') }}",
        "reply_markup": {
            "inline_keyboard": [
                {{ FOR list IN ref(service.api_price_list).nsort('service_id') }}
                    [
                        {
                            "text": "{{ list.name _' '_ list.descr }} - {{ list.cost }} ₽",
                            "callback_data": "admin:subs:change:current:confirm {{ userService.user_service_id _ ' ' _ list.service_id }}"
                        }
                    ],
                {{ END }}
                [
                    {
                        "text": "⬅️ Назад",
                        "callback_data": "admin:subs:id {{ userService.user_service_id }}"
                    }
                ],
                [
                    {
                        "text": "👨‍💻 Меню {{ menuRole = (user.settings.role == 'admin' ? 'администратора' : 'модератора'); menuRole; }}",
                        "callback_data": "admin:menu"
                    },
                    {
                        "text": "🏠 Главное меню",
                        "callback_data": "/menu"
                    }
                ]
            ]
        }
    }
}

<% CASE 'admin:subs:change:current:confirm' %>
{{ PROCESS checkAdminRights }}
{{
    nextService = args.1;
    data = ref(us.list_for_api('admin', 1, 'filter', {"user_service_id" = args.0})).first;
    userData = user.id(data.user_id);
    username = userData.full_name.replace('"', '\"');
    serviceData = service.id(data.service_id);
    userServiceNext = service.id(nextService);
    
    IF (ret = userData.us.id(data.user_service_id).change('service_id' = nextService));
        sendAlert(
            errtext="✅ Тариф для подписки $serviceData.name #$data.user_service_id пользователя $username (#$userData.user_id) изменен на $userServiceNext.name",
            redirect="admin:subs:id $data.user_service_id $userData.user_id"
        );
    END;
}}


<% CASE 'admin:subs:change:next' %>
{{
    # Check for admin or moderator rights
    PROCESS checkAdminRights;
    # Check right for change settings
    checkModeratorRights(right="changeSubs");
}}
{{
    userService = ref(us.list_for_api('admin', 1, 'filter', {"user_service_id" = args.0})).first;
    userData = user.id(userService.user_id);
    userServiceData = service.id(userService.service_id);
    userServiceNext = service.id(userService.next);
}}
{{ TEXT = BLOCK }}
⎘ Выберите следующий тариф для подписки {{ userServiceData.name }} пользователя {{ userData.full_name.replace('"', '\"')  }} ({{ userData.user_id }})

{{ IF userService.next != userService.service_id || userService.next != 0 }}
Следующий тариф: {{ userServiceNext.name }} ({{ userService.next }})
{{ END }}
{{ END }}

{
    "editMessageText": {
        "message_id": {{ message.message_id }},
        "parse_mode": "HTML",
        "text": "{{ TEXT.replace('\n','\n') }}",
        "reply_markup": {
            "inline_keyboard": [
                {{ FOR list IN ref(service.api_price_list).nsort('service_id') }}
                    [
                        {
                            "text": "{{ list.name _' '_ list.descr }} - {{ list.cost }} ₽",
                            "callback_data": "admin:subs:change:next:confirm {{ userService.user_service_id _ ' ' _ list.service_id }}"
                        }
                    ],
                {{ END }}
                [
                    {
                        "text": "⬅️ Назад",
                        "callback_data": "admin:subs:id {{ userService.user_service_id }}"
                    }
                ],
                [
                    {
                        "text": "👨‍💻 Меню {{ menuRole = (user.settings.role == 'admin' ? 'администратора' : 'модератора'); menuRole; }}",
                        "callback_data": "admin:menu"
                    },
                    {
                        "text": "🏠 Главное меню",
                        "callback_data": "/menu"
                    }
                ]
            ]
        }
    }
}

<% CASE 'admin:subs:change:next:confirm' %>
{{ PROCESS checkAdminRights }}
{{
    nextService = args.1;
    data = ref(us.list_for_api('admin', 1, 'filter', {"user_service_id" = args.0})).first;
    userData = user.id(data.user_id);
    username = userData.full_name.replace('"', '\"');
    serviceData = service.id(data.service_id);
    userServiceNext = service.id(nextService);

    
    IF (ret = userData.us.id(data.user_service_id).set("next", nextService));
        sendAlert(
            errtext="✅ Следующий тариф для подписки $serviceData.name #$data.user_service_id пользователя $username ($userData.user_id) изменён на $userServiceNext.name",
            redirect="admin:subs:id $data.user_service_id $userData.user_id"
        );
    END;
}}


<% CASE 'admin:subs:change:status' %>
{{
    # Check for admin or moderator rights
    PROCESS checkAdminRights;
    # Check right for change settings
    checkModeratorRights(right="changeSubs");
}}
{{
    data = ref(us.list_for_api('admin', 1, 'filter', {"user_service_id" = args.0})).first;
    userData = user.id(data.user_id);
    name = userData.full_name.replace('"', '\"');
    serviceData = service.id(data.service_id);

    IF data.status == 'ACTIVE';
        ret = userData.us.id(data.user_service_id).block;
    ELSIF data.status == 'BLOCK';
        ret = userData.us.id(data.user_service_id).activate;
    END;
    
    status = (data.status == 'ACTIVE' ? "🔴 заблокирована" : "🟢 активирована");
    sendAlert(
        errtext="✅ Услуга $serviceData.name ($data.user_service_id) пользователя $name ($userData.user_id) $status",
        redirect="admin:subs:id $data.user_service_id $userData.user_id"
    );
}}

<% CASE 'admin:subs:delete' %>
{{
    # Check for admin or moderator rights
    PROCESS checkAdminRights;
    # Check right for change settings
    checkModeratorRights(right="deleteSubs");
}}
{{
    data = ref(us.list_for_api('admin', 1, 'filter', {"user_service_id" = args.0})).first;
    userData = user.id(data.user_id);
    name = userData.full_name.replace('"', '\"');
    serviceData = service.id(data.service_id);

    IF data.status == 'BLOCK' || data.status == 'NOT PAID';
        IF (ret = userData.us.id(data.user_service_id).delete);
            sendAlert(
                errtext="❌ Услуга $serviceData.name ($data.user_service_id) пользователя $name ($userData.user_id) удалена!",
                redirect="admin:users:id:subs $userData.user_id"
            );
        END;
    END;
}}


<% CASE 'admin:users:id:pays' %>
{{
    # Check for admin or moderator rights
    PROCESS checkAdminRights;
    # Check right for change settings
    checkModeratorRights(right="listPays");
}}
{{
    limit = 5;
    offset = args.1 || 0;
    userData = user.id(args.0);
    userPays = ref(userData.pays.list_for_api('limit', limit, 'offset', offset ));
}}
{{ TEXT = BLOCK }}
👨‍💻 Управление платежами пользователя {{ userData.full_name.replace('"', '\"') }} ({{ userData.user_id }})

{{ END }}
{
    "editMessageText": {
        "message_id": {{ message.message_id }},
        "parse_mode": "HTML",
        "text": "{{ TEXT.replace('\n','\n') }}",
        "reply_markup": {
            "inline_keyboard": [
                {{ FOR item in userPays }}
                    [
                        {
                            "text": "(ID: {{ item.id }}), {{ item.money }} руб, {{ item.date }}",
                            "callback_data": "admin:pays:id {{ item.id }}"
                        }
                    ],
                {{ END }}
                {{ IF offset > 0 }}
                    [
                        {
                            "text": "⬅️ Назад",
                            "callback_data": "admin:users:id:pays {{ userData.user_id _' ' }} {{ offset - limit }}"
                        }
                    ],
                {{ END }}
                {{ IF userPays.size == limit }}
                    [
                        {
                            "text": "Ещё ➡️",
                            "callback_data": "admin:users:id:pays {{ userData.user_id _' ' }} {{ limit + offset }}"
                        }
                    ],
                {{ END }}
                [
                    {
                        "text": "➕ Добавить платеж",
                        "callback_data": "admin:pays:add {{ userData.user_id }}"
                    }
                ],
                [
                    {
                        "text": "⬅️ Информация о пользователе",
                        "callback_data": "admin:users:id {{ userData.user_id }}"
                    }
                ],
                [
                    {
                        "text": "👨‍💻👨‍💻 Меню {{ menuRole = (user.settings.role == 'admin' ? 'администратора' : 'модератора'); menuRole; }}",
                        "callback_data": "admin:menu"
                    },
                    {
                        "text": "🏠 Главное меню",
                        "callback_data": "/menu"
                    }
                ]
            ]
        }
    }
}

<% CASE 'admin:pays:id' %>
{{
    # Check for admin or moderator rights
    PROCESS checkAdminRights;
    # Check right for change settings
    checkModeratorRights(right="listPays");
}}
{{
    userPay = ref(pay.list_for_api('admin', 1, 'filter', {"id" = args.0})).first;
    payData = userPay.comment.object;
    payMethod = payData.payment_method;
    payCard = payMethod.card;
    userData = user.id(userPay.user_id);
	partnerData = user.id(data.comment.from_user_id);
}}
{{ TEXT = BLOCK }}
💸 Информация о платеже ID {{ userPay.id }} пользователя {{ userData.full_name.replace('"', '\"')  }} ({{ userData.user_id }})

Дата платежа: {{ userPay.date }}
Платежная система: {{ userPay.pay_system_id }}
Сумма: {{ userPay.money }} руб.

{{ IF data.comment.from_user_id }}
<blockquote>{{ data.comment.percent }}% от {{ userData.full_name.replace('"', '\"')  }} ({{ partnerData.user_id }})</blockquote>
{{ END }}

{{ IF data.comment.msg }}
<blockquote>{{ data.comment.msg }}</blockquote>
{{ END }}

{{ IF userPay.comment.comment }}
<b>Комментарий к платежу</b>
<blockquote>{{ userPay.comment.comment }}</blockquote>
{{ END }}

{{ IF payData }}
<b>Данные о платеже</b>
<blockquote>
ID в системе: {{ payData.id }}
Статус: {{ payData.status }}
{{ IF payCard }}
Тип карты: {{ payCard.card_type }}
Номер карты: {{ payCard.first6 }}******{{ payCard.last4 }}
Банк: {{ payCard.issuer_name }}
Страна банка: {{ payCard.issuer_country }}
Срок действия: {{ payCard.expiry_month }}/{{ payCard.expiry_year }}
{{ END }}
{{ IF payMethod.type == 'sbp' }}
Тип оплаты: СБП
Номер операции в СБП: {{ payMethod.sbp_operation_id }}
Бик Банка: {{ payMethod.payer_bank_details.bic }}
{{ END }}

{{ IF payMethod.title.match('YooMoney') }}
Кошелек YooMoney: {{ payMethod.title }}
ID кошелька: {{ payMethod.account_number }}
{{ END }}
</blockquote>
{{ END }}

{{ END }}

{
    "editMessageText": {
        "message_id": {{ message.message_id }},
        "parse_mode": "HTML",
        "text": "{{ TEXT.replace('\n','\n') }}",
        "reply_markup": {
            "inline_keyboard": [
    [
        {
            "text": "⬅️ Назад",
            "callback_data": "admin:users:id:pays {{ userPay.user_id }}"
        }
    ],
    [
        {
            "text": "👨‍💻 Меню {{ menuRole = (user.settings.role == 'admin' ? 'администратора' : 'модератора'); menuRole; }}",
            "callback_data": "admin:menu"
        },
        {
            "text": "🏠 Главное меню",
            "callback_data": "/menu"
        }
    ]
            ]
        }
    }
}

<% CASE 'admin:pays:add' %>
{{
    # Check for admin or moderator rights
    PROCESS checkAdminRights;
    # Check right for change settings
    checkModeratorRights(right="addPays");
}}
{{
    userData = user.id(args.0);
}}
{{ TEXT = BLOCK }}
💸 Выберите сумму, которую хотите начислить пользователю {{ userData.full_name.replace('"', '\"')  }} ({{ userData.user_id }})
Текущий баланс: {{ userData.balance }} руб.

{{ END }}
{
    "editMessageText": {
        "message_id": {{ message.message_id }},
        "parse_mode": "HTML",
        "text": "{{ TEXT.replace('\n','\n') }}",
        "reply_markup": {
            "inline_keyboard": [
                [
                    {
                        "text": "10 руб",
                        "callback_data": "admin:pays:add:confirm {{ userData.user_id }} 10"
                    },
                    {
                        "text": "20 руб",
                        "callback_data": "admin:pays:add:confirm {{ userData.user_id }} 20"
                    }
                ],
                [
                    {
                        "text": "50 руб",
                        "callback_data": "admin:pays:add:confirm {{ userData.user_id }} 50"
                    },
                    {
                        "text": "100 руб",
                        "callback_data": "admin:pays:add:confirm {{ userData.user_id }} 100"
                    }
                ],
                [
                    {{ FOR item IN ref(service.api_price_list('category', '%')).nsort('cost') }}
                        {
                            "text": "{{ item.name }} - {{ item.cost }}₽",
                            "callback_data": "admin:pays:add:confirm {{ userData.user_id _ ' ' }} {{ item.cost }}"
                        },
                    {{ END }}
                ],
                [
                    {
                        "text": "Ввести свою сумму",
                        "callback_data": "admin:pays:add:manual {{ userData.user_id }}"
                    }
                ],
                [
                    {
                        "text": "⬅️ Назад",
                        "callback_data": "admin:users:id:pays {{ userData.user_id }}"
                    }
                ],
                [
                    {
                        "text": "👨‍💻 Меню {{ menuRole = (user.settings.role == 'admin' ? 'администратора' : 'модератора'); menuRole; }}",
                        "callback_data": "admin:menu"
                    },
                    {
                        "text": "🏠 Главное меню",
                        "callback_data": "/menu"
                    }
                ]
            ]
        }
    }
}

<% CASE 'admin:pays:add:manual' %>
{{
    # Check for admin or moderator rights
    PROCESS checkAdminRights;
    # Check right for change settings
    checkModeratorRights(right="addPays");
}}
{{
    userData = user.id(args.0);

    ret = user.set_settings({'state' => 'awaiting_amount'});
    ret = user.set_settings({'bot' => {'switchUser' => userData.user_id} });
}}

{{ TEXT = BLOCK }}
💬 Введите сумму для пополнения баланса пользователя {{ userData.full_name.replace('"', '\"') }}
{{ END }}
{{ notification(TEXT=TEXT, force=1) }}


<% CASE 'admin:pays:add:confirm' %>
{{
    # Check for admin or moderator rights
    PROCESS checkAdminRights;
    # Check right for change settings
    checkModeratorRights(right="addPays");
}}
{{
    userData = user.id(args.0);
    name = userData.full_name.replace('"', '\"');
    amount = args.1;

    IF (pay = userData.payment('money', amount, 'pay_system_id', 'manual'));
        sendAlert(
            errtext="✅ Баланс пользователя $name ($userData.user_id) пополнен на $amount руб.\nТекущий баланс $userData.balance руб.",
            redirect="admin:pays:add $userData.user_id"
        );
    END;
}}

<% CASE 'admin:users:id:bonuses' %>
{{
    # Check for admin or moderator rights
    PROCESS checkAdminRights;
    # Check right for change settings
    checkModeratorRights(right="listBonus");
}}
{{
    limit = 5;
    offset = (args.1 || 0);
    userData = user.id(args.0);
    userBonuses = ref(bonus.list_for_api('admin', 1, 'limit', limit, 'offset', offset, 'filter', {"user_id" = userData.user_id}));
}}
{{ TEXT = BLOCK }}
👨‍💻 Управление бонусами пользователя {{ userData.full_name.replace('"', '\"')  }} ({{ userData.user_id }})

Баланс бонусов: {{ userData.get_bonus }} руб.
{{ END }}

{
    "editMessageText": {
        "message_id": {{ message.message_id }},
        "parse_mode": "HTML",
        "text": "{{ TEXT.replace('\n','\n') }}",
        "reply_markup": {
            "inline_keyboard": [
                {{ FOR item in userBonuses }}
                    [
                        {
                            "text": "ID: {{ item.id }} — {{ item.bonus }} руб.",
                            "callback_data": "admin:bonuses:id {{ item.id _ ' ' _ offset }}"
                        }
                    ],
                {{ END }}
                {{ IF offset > 0 }}
                    [
                        {
                            "text": "⬅️ Назад",
                            "callback_data": "admin:users:id:bonuses {{ userData.user_id _' ' }} {{ offset - limit }}"
                        }
                    ],
                {{ END }}
                {{ IF userBonuses.size == limit }}
                    [
                        {
                            "text": "Ещё ➡️",
                            "callback_data": "admin:users:id:bonuses {{ userData.user_id _' ' }} {{ limit + offset }}"
                        }
                    ],
                {{ END }}
                [
                    {
                        "text": "➕ Добавить бонусы",
                        "callback_data": "admin:bonuses:add {{ userData.user_id }}"
                    }
                ],
                [
                    {
                        "text": "⬅️ Информация о пользователе",
                        "callback_data": "admin:users:id {{ userData.user_id }}"
                    }
                ],
                [
                    {
                        "text": "👨‍💻 Меню {{ menuRole = (user.settings.role == 'admin' ? 'администратора' : 'модератора'); menuRole; }}",
                        "callback_data": "admin:menu"
                    },
                    {
                        "text": "🏠 Главное меню",
                        "callback_data": "/menu"
                    }
                ]
            ]
        }
    }
}

<% CASE 'admin:bonuses:id' %>
{{
    # Check for admin or moderator rights
    PROCESS checkAdminRights;
    # Check right for change settings
    checkModeratorRights(right="listBonus");
}}
{{
    offset = args.1;
    data = ref(bonus.list_for_api('admin', 1, 'limit', limit, 'offset', offset, 'filter', {"id" = args.0})).first;
    userData = user.id(data.user_id);
    partnerData = user.id(data.comment.from_user_id)
}}
{{ TEXT = BLOCK }}
💸 Информация о начислении бонусов ID {{ data.id }} пользователю {{ userData.full_name.replace('"', '\"')  }} ({{ userData.user_id }})

ID начисления: {{ data.id }}
Дата начисления: {{ data.date }}
Сумма начисления: {{ data.bonus }} руб.

{{ IF data.comment.from_user_id }}
<blockquote>{{ data.comment.percent }}% от {{ userData.full_name.replace('"', '\"')  }} ({{ partnerData.user_id }})</blockquote>
{{ END }}

{{ IF data.comment.msg }}
<blockquote>{{ data.comment.msg }}</blockquote>
{{ END }}
{{ END }}
{
    "editMessageText": {
        "message_id": {{ message.message_id }},
        "parse_mode": "HTML",
        "text": "{{ TEXT.replace('\n','\n') }}",
        "reply_markup": {
            "inline_keyboard": [
                [
                    {
                        "text": "⬅️ Назад",
                        "callback_data": "admin:users:id:bonuses {{ userData.user_id _ ' ' _ offset }}"
                    }
                ],
                [
                    {
                        "text": "👨‍💻 Меню {{ menuRole = (user.settings.role == 'admin' ? 'администратора' : 'модератора'); menuRole; }}",
                        "callback_data": "admin:menu"
                    },
                    {
                        "text": "🏠 Главное меню",
                        "callback_data": "/menu"
                    }
                ]
            ]
        }
    }
}

<% CASE 'admin:bonuses:add' %>
{{
    # Check for admin or moderator rights
    PROCESS checkAdminRights;
    # Check right for change settings
    checkModeratorRights(right="addBonus");
}}
{{
    userData = user.id(args.0);
}}
{{ TEXT = BLOCK }}
💸 Выберите кол-во бонусов, которые хотите начислить пользователю {{ userData.full_name.replace('"', '\"')  }} ({{ userData.user_id }})
Текущий баланс бонусов {{ userData.get_bonus }} руб.

{{ END }}
{
    "editMessageText": {
        "message_id": {{ message.message_id }},
        "parse_mode": "HTML",
        "text": "{{ TEXT.replace('\n','\n') }}",
        "reply_markup": {
            "inline_keyboard": [
                [
                    {
                        "text": "10 руб",
                        "callback_data": "admin:bonuses:add:confirm {{ userData.user_id }} 10"
                    },
                    {
                        "text": "20 руб",
                        "callback_data": "admin:bonuses:add:confirm {{ userData.user_id }} 20"
                    },
                    {
                        "text": "30 руб",
                        "callback_data": "admin:bonuses:add:confirm {{ userData.user_id }} 30"
                    },
                    {
                        "text": "40 руб",
                        "callback_data": "admin:bonuses:add:confirm {{ userData.user_id }} 40"
                    }
                ],
                [
                    {
                        "text": "50 руб",
                        "callback_data": "admin:bonuses:add:confirm {{ userData.user_id }} 50"
                    },
                    {
                        "text": "100 руб",
                        "callback_data": "admin:bonuses:add:confirm {{ userData.user_id }} 100"
                    },
                    {
                        "text": "150 руб",
                        "callback_data": "admin:bonuses:add:confirm {{ userData.user_id }} 150"
                    },
                    {
                        "text": "200 руб",
                        "callback_data": "admin:bonuses:add:confirm {{ userData.user_id }} 200"
                    }
                ],
                [
                    {
                        "text": "Убрать {{ userData.get_bonus }}",
                        "callback_data": "admin:bonuses:add:confirm {{ userData.user_id }} -{{ userData.get_bonus }}"
                    }
                ],
                [
                    {
                        "text": "⬅️ Назад",
                        "callback_data": "admin:users:id:bonuses {{ userData.user_id }}"
                    }
                ],
                [
                    {
                        "text": "👨‍💻 Меню {{ menuRole = (user.settings.role == 'admin' ? 'администратора' : 'модератора'); menuRole; }}",
                        "callback_data": "admin:menu"
                    },
                    {
                        "text": "🏠 Главное меню",
                        "callback_data": "/menu"
                    }
                ]
            ]
        }
    }
}

<% CASE 'admin:bonuses:add:confirm' %>
{{
    # Check for admin or moderator rights
    PROCESS checkAdminRights;
    # Check right for change settings
    checkModeratorRights(right="addBonus");
}}
{{
    userData = user.id(args.0);
    name = userData.full_name.replace('"', '\"');
    amount = args.1;

    IF amount < 0;
        ret = userData.set_bonus('bonus', amount, 'comment', {'msg' => 'Ручная корректировка от администратора'});
    ELSE;
        IF (ret = userData.set_bonus('bonus', amount, 'comment', {'msg' => 'Ручное начисление от администратора'}));
            notification(
                chat_id="$userData.settings.telegram.chat_id",
                TEXT="🎁 Вам начислено $amount бонусов на счет от администратора"
            ); ",";
        END;
    END;

    sendAlert(
        errtext="✅ Баланс бонусов пользователя $name ($userData.user_id) изменен на $amount руб.\nТекущий баланс $userData.get_bonus руб.",
        redirect="admin:bonuses:add $userData.user_id"
    );
}}

<% CASE 'admin:withdraws:id' %>
{{
    data = ref(wd.list_for_api('admin', 1, 'filter', {"withdraw_id" = args.0})).first;
    userData = user.id(data.user_id);
}}
{{ TEXT = BLOCK }}
💸 Информация о списании №{{ data.withdraw_id }}

Пользователь: {{ userData.full_name.replace('"', '\"')  }} ({{ userData.user_id }})

Услуга: {{ data.name }} ({{ data.user_service_id }})
Стоимость: {{ data.cost }}
Дата создания: {{ data.create_date }}
Дата списания: {{ data.withdraw_date }}
Дата окончания по списанию: {{ data.end_date }}
Кол-во месяцев: {{ data.months }}

<b>Списание:</b>
<blockquote>
Скидка: {{ data.discount }}%
Бонусов: {{ data.bonus }} руб
<b>Всего: {{ data.total }}</b>

</blockquote>
{{ END }}

{
    "editMessageText": {
        "message_id": {{ message.message_id }},
        "parse_mode": "HTML",
        "text": "{{ TEXT.replace('\n','\n') }}",
        "reply_markup": {
            "inline_keyboard": [
    [
        {
            "text": "⬅️ Назад",
            "callback_data": "admin:subs:id {{ data.user_service_id _ ' ' _  userData.user_id }}"
        }
    ],
    [
        {
            "text": "👨‍💻 Меню {{ menuRole = (user.settings.role == 'admin' ? 'администратора' : 'модератора'); menuRole; }}",
            "callback_data": "admin:menu"
        },
        {
            "text": "🏠 Главное меню",
            "callback_data": "/menu"
        }
    ]
]
        }
    }
}

<% CASE 'admin:users:search' %>
{{
    # Set state for user
    ret = user.set_settings({'state' => 'awaiting_search'});
}}
{{ TEXT = BLOCK }}
💬 <b>Введите ID пользователя</b>
{{ END }}
{{ notification(TEXT=TEXT, force=1) }}

<% CASE ['notification:promo'] %>

{{ TEXT = BLOCK }}
✅ <b>Промокод {{ args.0 }} успешно применён!</b>
{{ END }}

{{ BUTTONS = BLOCK }}
    [
        {
            "text": "👤 Личный кабинет",
            "callback_data": "user:cabinet"
        }
    ],
    [
        {
            "text": "🏠 Главное меню",
            "callback_data": "{{ mainMenuCmd }}"
        }
    ]
{{ END }}
{{ notification(TEXT=TEXT, BUTTONS=BUTTONS) }}


<% CASE 'notification:create' %>
{{
    USE date;
    usi = args.0;
    service = user.services.list_for_api('usi', usi);
}}
{{ TEXT = BLOCK }}
✅ <b>Ключ #{{ service.user_service_id }} - {{ service.name }} активирован</b>

🗓️ <b>Дата окончания</b>: {{ date.format(service.expire, '%d.%m.%Y') }}

<blockquote><b>Для подключения нажмите 🔐 Подключиться</b></blockquote>
{{ END }}

{{ BUTTONS = BLOCK }}
    [
        {
            "text": "🔐 Подключиться",
            "callback_data": "user:keys:id {{ service.user_service_id }}"
        }
    ],
    [
        {
            "text": "🏠 Главное меню",
            "callback_data": "{{ mainMenuCmd }}"
        }
    ]
{{ END }}
{{ notification(TEXT=TEXT, BUTTONS=BUTTONS) }}

<% CASE 'notification:block' %>
{{
    USE date;
    usi = args.0;
    service = user.services.list_for_api('usi', usi);
}}
{{ TEXT = BLOCK }}
⭕️ <b>Ключ #{{ service.user_service_id }} - {{ service.name }} заблокирован</b>
{{ END }}

{{ BUTTONS = BLOCK }}
    [
        {
            "text": "🔑 Мои ключи",
            "callback_data": "/list"
        }
    ],
    [
        {
            "text": "🏠 Главное меню",
            "callback_data": "{{ mainMenuCmd }}"
        }
    ]
{{ END }}
{{ notification(TEXT=TEXT, BUTTONS=BUTTONS) }}

<% CASE ['notification:activate'] %>
{{
    USE date;
    usi = args.0;
    service = user.services.list_for_api('usi', usi);
}}
{{ TEXT = BLOCK }}
✅ <b>Ключ #{{ service.user_service_id }} - {{ service.name }} активирован</b>

🗓️ <b>Дата окончания</b>: {{ date.format(service.expire, '%d.%m.%Y') }}

<blockquote>Для подключения нажмите 🔐 Подключиться</blockquote>
{{ END }}

{{ BUTTONS = BLOCK }}
    [
        {
            "text": "🔐 Подключиться",
            "callback_data": "user:keys:id {{ service.user_service_id }}"
        }
    ],
    [
        {
            "text": "🏠 Главное меню",
            "callback_data": "{{ mainMenuCmd }}"
        }
    ]
{{ END }}
{{ notification(TEXT=TEXT, BUTTONS=BUTTONS) }}


<% CASE 'notification:prolongate' %>
{{
    USE date;
    usi = args.0;
    service = user.services.list_for_api('usi', usi);
}}
{{ TEXT = BLOCK }}
✅ <b>Ключ #{{ service.user_service_id }} - {{ service.name }} продлён!</b>

🗓️ Дата окончания: {{ date.format(service.expire, '%d.%m.%Y') }}

<blockquote>Для подключения нажмите 🔐 Подключиться</blockquote>
{{ END }}

{{ BUTTONS = BLOCK }}
    [
        {
            "text": "🔐 Подключиться",
            "callback_data": "user:keys:id {{ service.user_service_id }}"
        }
    ],
    [
        {
            "text": "🏠 Главное меню",
            "callback_data": "{{ mainMenuCmd }}"
        }
    ]
{{ END }}
{{ notification(TEXT=TEXT, BUTTONS=BUTTONS) }}

<% CASE 'notification:forecast' %>
{{
    USE date;
    usi = args.0;
    service = user.services.list_for_api('usi', usi);
    cost = user.pays.forecast('blocked', 1).total;
}}
{{ TEXT = BLOCK }}
💰 <b>Необходимо оплатить следующие ключи</b>

    {{ FOR item in ref(user.pays.forecast.items('blocked', 1)) }}
<code>
🔑 #<b>{{ item.user_service_id }} - {{ item.name }}</b>
        {{ IF item.expire }}
🗓️ <b>Дата окончания</b>: {{ date.format(item.expire, '%d.%m.%Y') }}
        {{ END }}
</code>
    {{ END }}

<b>Баланс</b>: {{ user.balance }} руб.
<b>Баланс необходимо пополнить на </b>{{ cost }} руб.
{{ END }}

{{ BUTTONS = BLOCK }}
    [
        {
            "text": "➕ Пополнить {{ cost }} руб.",
            "web_app": {
                "url": "{{ config.api.url }}/shm/v1/public/tg_payment?format=html"
            }
        }
    ],
    [
        {
            "text": "🔑 Мои ключи",
            "callback_data": "/list"
        }
    ]
{{ END }}
{{ notification(TEXT=TEXT, BUTTONS=BUTTONS) }}

<% CASE 'notification:not_enough_money' %>
{{
    cost = user.pays.forecast('blocked',1).total;
}}
{{ TEXT = BLOCK }}
ℹ️ <b>Для активации следующих ключей</b>

    {{ FOR item in ref(user.pays.forecast.items) }}
    {{ # NEXT IF item.status != 'NOT PAID'# }}
<code>🔑 #<b>{{ item.user_service_id }} - {{ item.name }}</b></code>
    {{ END }}

<b>Необходимо оплатить </b>{{ cost }} руб.
{{ END }}

{{ BUTTONS = BLOCK }}
    [
        {
            "text": "➕ Пополнить {{ cost }} руб.",
            "web_app": {
                "url": "{{ config.api.url }}/shm/v1/public/tg_payments_webapp?format=html&user_id={{ user.id }}"
            }
        }
    ],
    [
        {
            "text": "🔑 Мои ключи",
            "callback_data": "/list"
        }
    ]
{{ END }}
{{ notification(TEXT=TEXT, BUTTONS=BUTTONS) }}


<% CASE 'notification:payment' %>
{{ amount = user.pays.last.money }}
{{ total = user.balance }}
{{
    amount = user.pays.last.money;
}}
{{ TEXT = BLOCK }}
✅ <b>Платёж на сумму {{ amount }} руб. зачислен на ваш баланс.</b>

💰 <b>Баланс</b>: {{ user.balance }}
{{ END }}

{{ BUTTONS = BLOCK }}
    [
        {
            "text": "👤 Личный кабинет",
            "callback_data": "user:cabinet"
        }
    ],
    [
        {
            "text": "🏠 Главное меню",
            "callback_data": "{{ mainMenuCmd }}"
        }
    ]
{{ END }}
{{ notification(TEXT=TEXT, BUTTONS=BUTTONS) }}

<% CASE 'notification:promo' %>

{{ TEXT = BLOCK }}
✅ <b>Промокод {{ args.0 }} успешно применён!</b>
{{ END }}

{{ BUTTONS = BLOCK }}
    [
        {
            "text": "👤 Личный кабинет",
            "callback_data": "user:cabinet"
        }
    ],
    [
        {
            "text": "🏠 Главное меню",
            "callback_data": "{{ mainMenuCmd }}"
        }
    ]
{{ END }}
{{ notification(TEXT=TEXT, BUTTONS=BUTTONS) }}

<% CASE 'promocode' %>
{{
    # Устанавливаем переменную
    ret = user.set_settings({'state' => 'awaiting_promocode'});
    IF user.settings.bot.reqPromo;
        temp = user.settings.bot.reqPromo + 1;
        delete(msgID=[temp, user.settings.bot.reqPromo, message.message_id]);
        ret = user.set_settings({'bot' => {'reqPromo' => message.message_id} });
    ELSE;
        ret = user.set_settings({'bot' => {'reqPromo' => message.message_id} });
    END;
}}
{{ TEXT = BLOCK }}
💬 <b>Введите ваш промокод:</b>
{{ END }}

{{ notification(TEXT=TEXT, force=1) }}


<% CASE DEFAULT %>

{{ IF user.settings.state == 'awaiting_search'}}
    {{
        temp = message.message_id - 1;
        delete(msgID=[message.message_id, temp]);
        IF message.text.match('^[1-9]\d*$');
            searchString = message.text;
            ret = user.set_settings({'state' => ''});
            ret = ref(user.list_for_api('admin', 1, 'filter', {"user_id" = searchString} ));

            IF (ret.size > 0);
                resultID = ret.first.user_id;
                redirect(callback="admin:users:id $resultID");
            ELSE;
                TEXT = "⭕️ Пользователь с ID $searchString не найден!";
            END;

        ELSE;
            ret = user.set_settings({'state' => ''});
            TEXT = "❌ <b>Ошибка:</b> ID может содержать только положительное число!";
        END;

        notification(TEXT=TEXT);
    }}
	
{{ ELSIF user.settings.state == 'awaiting_user_message' }}
{{
    temp = message.message_id - 1;
    delete(msgID=[message.message_id, temp]);

    IF message.text.length > 0;
        userID = user.settings.temp_user_id;
        messageText = message.text;
        
        # Очистка состояния
        ret = user.set_settings({'state' => '', 'temp_user_id' => ''});

        # Отправка сообщения пользователю
        notification(
            TEXT="📩 Сообщение от администратора:\n\n<blockquote>$messageText</blockquote>",
            user_id=userID
        );

        TEXT = "✅ Сообщение отправлено пользователю #$userID!";
    ELSE;
        ret = user.set_settings({'state' => ''});
        TEXT = "❌ <b>Ошибка:</b> Сообщение не может быть пустым!";
    END;

    notification(TEXT=TEXT);
}}


{{ ELSIF user.settings.state == 'awaiting_promocode' }}
    {{
        IF user.settings.bot.reqPromo;
            temp = user.settings.bot.reqPromo + 1;
            temp2 = user.settings.bot.reqPromo - 1;
            delete(msgID=[temp, temp2, user.settings.bot.reqPromo, message.message_id]);
            ret = user.set_settings({'bot' => {'reqPromo' => message.message_id} });
        END;

        # Проверяем, что введено
        IF message.text.match('^[a-zA-Z0-9_-]+$');
            promocode = message.text;
            ret = user.set_settings({'state' => ''});
            
            IF promo.apply(promocode);
                TEXT = "✅ <b>Промокод $promocode применён!</b>";
            ELSE;
                TEXT = "⭕️ <b>Промокод $promocode не найден!</b>";
            END;

        ELSE;
            TEXT = "❌ <b>Ошибка:</b> Промокод может содержать только буквы, цифры, тире (-) и нижнее подчёркивание (_).";
        END;
    }}

    {{ BUTTONS = BLOCK }}
        [
            {
                "text": "🏷️ Ввести ещё",
                "callback_data": "promocode"
            }
        ],
        [
            {
                "text": "🏠 Главное меню",
                "callback_data": "/menu"
            }
        ]
    {{ END }}
    {{ notification(TEXT=TEXT, BUTTONS=BUTTONS) }}


{{ ELSIF user.settings.state == 'awaiting_amount' AND user.settings.bot.switchUser }}
    {{
        userData = user.id(user.settings.bot.switchUser);
        IF message.text.match('^-?\d+(\.\d+)?$');
            amount = message.text;

            IF (ret = userData.payment('money', amount, 'pay_system_id', 'manual'));
                TEXT = "✅ <b>Баланс пользователя $userData.user_id пополнен на $amount руб.</b>\nТекущий баланс: $userData.balance руб.";
            ELSE;
                TEXT = "⭕️ Ошибка пополнения. Повторите попытку.";
            END;

            ret = user.set_settings({'state' => ''});
            ret = user.set_settings({'bot' => {'switchUser' => ''} });
        ELSE;
            TEXT = "⭕️ Ошибка пополнения. Повторите попытку.";
        END;
    }}

    {{ BUTTONS = BLOCK }}
    [
        {
            "text": "ℹ️ Информация о пользователе",
            "callback_data": "admin:users:id {{ userData.user_id }}"
        }
    ],
    [
        {
            "text": "🏠 Главное меню",
            "callback_data": "/menu"
        }
    ]
{{ END }}
{{ notification(TEXT=TEXT, BUTTONS=BUTTONS) }}

{{ ELSIF message.document OR message.photo }}
{
    "forwardMessage": {
        "chat_id": {{ config.shmcustomlab.payment_group }},
        "from_chat_id": {{ message.chat.id }},
        "message_id": {{ message.message_id }}
    }
},
{{ TEXT = BLOCK }}
<b>Спасибо, что выбрали {{ config.shmcustomlab.service_name }}</b>

В ближайшее время ваш платеж будет проверен. Как только проверка завершится, вы получите уведомление от бота
{{ END }}
{{ AmmountToPay = user.pays.forecast('blocked',1).total }}
{
    "deleteMessage": { "message_id": {{ message.message_id }} }
},
{
    "deleteMessage": { "message_id": {{ message.message_id - 1 }} }
},
{
    "sendMessage": {
        "text": "{{ TEXT.replace('\n','\n') }}",
        "reply_markup" : {
            "inline_keyboard": [
                [
                    {
                        "text": "Главное меню",
                        "callback_data": "/menu"
                    }
                ] 
            ]
        }
    }
},
{{ PERL }}
    use Core::Utils qw(
        passgen
    );
    my $passgen = passgen(10);
    $stash->set('pass', $passgen);
{{ END }}
{{ PaymentID = pass }}
{{ ret = user.set_settings({ $PaymentID => 0 }) }}
{{ item = ref(user.services.list_for_api( 'category', 'vpn-%' )).first }}
{{ con = ref(user.services.list_for_api( 'category', 'vpn-mz%' )).size }}
                {{ FOR env IN ref( user.services.list_for_api( 'category', '%' ) ) }}
                {{ SWITCH item.status }}
                  {{ CASE 'ACTIVE' }}
                  {{ icon = '✅ ' }}
                  {{ status = 'Активная' }}
                  {{ CASE 'BLOCK' }}
                  {{ icon = '❌ ' }}
                  {{ status = 'Заблокирована' }}
                  {{ CASE 'NOT PAID' }}
                  {{ icon = '💰 ' }}
                  {{ status = 'Ожидает оплаты' }}
                  {{ CASE }}
                  {{ icon = '⏳ ' }}
                  {{ status = 'Обработка' }}
                {{ END }}
                {{ END }}
{{ TEXT = BLOCK }}
<b>Поступил запрос на прием платежа</b>
Пользователь: ({{ user.id }})
Имя: {{ user.full_name }}, телеграм: @{{ user.settings.telegram.login }}
Колличество услуг у него: {{ con }}
ID платежа: {{ PaymentID }}
Сумма к оплате {{ AmmountToPay }}

Проверьте квитанцию и подтвердите оплату с помощью кнопки внизу
При необходимости скорректируйте сумму платежа перед подтверждением
{{ END }}
{{ encoded_status = status FILTER uri }}
{{ encoded_name = user.full_name FILTER uri }}
{{ encoded_plan = item.name FILTER uri }}
{
    "sendMessage": {
        "chat_id": {{ config.shmcustomlab.payment_group }},
        "text": "{{ TEXT.replace('\n','\n') }}",
        "reply_markup": {
            "inline_keyboard": [
                [
                    {
                        "text": "💳 Подтвердить оплату",
                        "url": "{{ config.api.url }}/shm/v1/public/HTML_payment?uid={{ user.id }}&telegram={{ user.settings.telegram.login }}&services={{ con }}&cost={{ AmmountToPay }}&serviceNumber={{ item.user_service_id }}&serviceStatus={{ encoded_status }}&PaymentID={{ PaymentID }}&format=html"
                    }
                ]
            ]
        }
    }
}
{{ ELSE }}
{
    "forwardMessage": {
        "chat_id": {{ config.shmcustomlab.admin_group }},
        "from_chat_id": {{ message.chat.id }},
        "message_id": {{ message.message_id }}
    }
},
{
    "sendMessage": {
        "text": "ОШИБКА! Не понимаю, что вы мне прислали. Если у Вас есть вопросы, пишите в чат поддержки",
        "reply_to_message_id": {{ message.message_id }},
        "reply_markup": {
            "inline_keyboard": [
                [
                    {
                        "text": "💡 Чат поддержки",
                        "url": "{{ config.setting_tgmy_bot.supportUrl }}"
                    }
                ]
            ]
        }
    }
}
{{ END }}
<% END %>
