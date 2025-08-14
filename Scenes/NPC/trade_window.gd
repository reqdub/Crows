extends Control

var item_name
var item_amount
var item_price

func set_item(_item_name, _item_amount, _item_price):
	item_name = _item_name
	item_amount = _item_amount
	item_price = _item_price
	$Text/Label.set_text(str("Желаете приобрести ", item_amount, " ", item_name, " за ", (item_price * item_amount), " монет?"))
	$Text2/PriceLabel.set_text(str(item_price * item_amount))
