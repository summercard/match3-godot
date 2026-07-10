class_name BlessingProvider
extends RefCounted

const MailContentDBScript = preload("res://src/data/mail_content_db.gd")


func build_simulated_blessing(seed: int, adventurer: Dictionary) -> Dictionary:
	var template := MailContentDBScript.get_blessing_template(seed)
	var attachment := MailContentDBScript.get_blessing_attachment(seed * 17 + str(adventurer.get("id", "")).hash())
	return {
		"source": "stranger_blessing",
		"sender_name": str(template.get("sender", "远方的冒险者")),
		"title": str(template.get("title", "一份温暖的祝福")),
		"body": str(template.get("body", "远方一位陌生冒险者，托精灵给你送来了祝福。")),
		"attachments": [attachment],
	}
