extends RefCounted
class_name Languages

## Idiomas del juego. Todos los textos están en res://i18n/textos.csv: una fila
## por texto (columna "keys" = la clave que usan escenas y scripts) y una columna
## por idioma. Las escenas ponen la CLAVE en el text de sus Label/Button (Godot
## la traduce solo y la vuelve a traducir al cambiar de idioma); en código se
## usa tr("CLAVE") (o Languages.text("CLAVE") desde funciones estáticas).
##
## Agregar un idioma (p. ej. francés):
##   1. Agregar la columna "fr" a i18n/textos.csv y traducir cada fila (la fila
##      LANGUAGE_NAME es el nombre que se muestra en el selector: "Français").
##   2. Abrir el proyecto en Godot (genera i18n/textos.fr.translation) y sumarlo
##      en Proyecto → Configuración → Localización → Traducciones.
##   3. Opcional: imágenes con texto dibujado traducidas, con el mismo nombre, en
##      una subcarpeta con el código del idioma (assets/ui/fr/portada.png). Si no
##      están, se usa la original (ver localized_texture).
## Nada más: el selector de idioma (menú principal y Ajustes) los lista solos.
##
## El idioma elegido lo guarda SettingsManager (set_language).

## Idioma de los textos originales (y el de respaldo si falta una traducción).
const DEFAULT := "es"

## Códigos de los idiomas disponibles (los que tienen traducción cargada), con
## el idioma por defecto primero.
static func available() -> PackedStringArray:
	var result := PackedStringArray([DEFAULT])
	var others := Array(TranslationServer.get_loaded_locales())
	others.sort()
	for code: String in others:
		if not result.has(code):
			result.append(code)
	return result

## Nombre del idioma en ese mismo idioma ("Español", "English"…).
static func name_of(code: String) -> String:
	var translation := TranslationServer.get_translation_object(code)
	if translation != null:
		var name := String(translation.get_message("LANGUAGE_NAME"))
		if name != "":
			return name
	return TranslationServer.get_locale_name(code)

## El idioma del sistema si el juego lo tiene; si no, el por defecto.
static func system_default() -> String:
	var code := OS.get_locale_language()
	return code if available().has(code) else DEFAULT

## El idioma que sigue a [param code] en la lista (para un botón que los recorre).
static func next_after(code: String) -> String:
	var list := available()
	var i := list.find(code)
	return list[(i + 1) % list.size()]

## Idioma actual (código).
static func current() -> String:
	return TranslationServer.get_locale().get_slice("_", 0)

## Traduce una clave (para código estático, donde no hay tr()).
static func text(key: String) -> String:
	return String(TranslationServer.translate(key))

## La versión en el idioma actual de una imagen con texto dibujado: el mismo
## archivo dentro de una subcarpeta con el código del idioma
## (res://assets/ui/portada.png → res://assets/ui/en/portada.png). Si no existe,
## devuelve la original.
static func localized_texture(original: Texture2D) -> Texture2D:
	if original == null or original.resource_path == "":
		return original
	var path := original.resource_path
	var variant := "%s/%s/%s" % [path.get_base_dir(), current(), path.get_file()]
	if current() != DEFAULT and ResourceLoader.exists(variant):
		return load(variant) as Texture2D
	return original
