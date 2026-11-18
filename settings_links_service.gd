class_name SettingsLinksService
extends RefCounted

const CONTACT_URL := ""
const TERMS_URL := ""
const PRIVACY_URL := ""
const RESTORE_EMPTY_MESSAGE := "No hay compras para restaurar."
const MISSING_LINK_MESSAGE := "Todavia no hay un enlace configurado."

static func is_configured(url: String) -> bool:
	return not str(url).strip_edges().is_empty()

static func restore_purchases_message() -> String:
	return RESTORE_EMPTY_MESSAGE

static func missing_link_message() -> String:
	return MISSING_LINK_MESSAGE
