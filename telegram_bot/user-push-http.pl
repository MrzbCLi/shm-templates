{{ IF event_name == "FORECAST" }}
{{ TEXT = BLOCK }}
Уведомляем Вас о сроках действия услуг:
{{ FOR item IN user.pays.forecast.items }}
- Услуга: {{ item.name }}
  Стоимость: {{ item.total }} руб.
  {{ IF item.expire }}
  Истекает: {{ item.expire }}
  {{ END }}
{{ END }}
{{ IF user.pays.forecast.dept }}
Погашение задолженности: {{ user.pays.forecast.dept }} руб.
{{ END }}

Итого к оплате: {{ user.pays.forecast.total }} руб.

Услуги, которые не будут оплачены до срока их истечения, будут приостановлены.
{{ END }}
{{
  toJson({
    text= TEXT
    chat_id= user.settings.telegram.chat_id
    reply_markup = { 
        inline_keyboard = [
                    [
                        {
                            text = "Главное меню"
                            callback_data = "/menu"
                        }
                    ]
            ]
    }
  })
}}
{{ END }}
{{ IF event_name == "CREATE" }}
{{ TEXT = BLOCK }}
VPN активирован!
{{ END }}
{{
  toJson({
    text= TEXT
    chat_id= user.settings.telegram.chat_id
    reply_markup = { 
        inline_keyboard = [
                    [
                        {
                            text = "✅ Установить"
                            callback_data = '/notifications_active '_ us.user_service_id                        
}
                    ]
            ]
    }
  })
}}
{{ END }}
{{ IF event_name == "PAYMENT" }}
{{ TEXT = BLOCK }}
💸 Твой платёж на сумму {{ user.pays.last.money }} руб. зачислен!
🔥 Приглашай друзей и получай VPN бесплатно.
{{ END }}
{{
  toJson({
    text= TEXT
    chat_id= user.settings.telegram.chat_id
  })
}}
{{ END }}
{{ IF event_name == "BONUS" }}
{{ TEXT = BLOCK }}
🔥 Тебе зачислены бонусы в размере: {{ bonus.amount }} руб.
{{ END }}
{{
  toJson({
    text= TEXT
    chat_id= user.settings.telegram.chat_id
  })
}}
{{ END }}
{{ IF event_name == "BLOCK" }}
{{ TEXT = BLOCK }}
❌ Услуга {{ us.name }} заблокирована. Пополни счёт для разблокировки.
🔥 Приглашай друзей и получай бесплатно.
{{ END }}
{{
  toJson({
    text= TEXT
    chat_id= user.settings.telegram.chat_id
  })
}}
{{ END }}
{{ IF event_name == "REMOVE" }}
{{ TEXT = BLOCK }}
Услуга {{ us.name }} удалена. Закажи новую 👉  /start
{{ END }}
{{
  toJson({
    text= TEXT
    chat_id= user.settings.telegram.chat_id
  })
}}
{{ END }}
{{ IF event_name == "ACTIVATE" }}
{{ TEXT = BLOCK }}
VPN активирован!
{{ END }}
{{
  toJson({
    text= TEXT
    chat_id= user.settings.telegram.chat_id
    reply_markup = { 
        inline_keyboard = [
                    [
                        {
                            text = "✅ Установить"
                            callback_data = '/notifications_active '_ us.user_service_id                        
}
                    ]
            ]
    }
  })
}}
{{ END }}
