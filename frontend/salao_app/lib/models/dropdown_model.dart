/// Par rótulo/valor usado por todo componente de seleção.
class DropdownModel {
  /// Texto exibido.
  final String key;

  /// Valor real (id, enum, `DateTime`…).
  final Object value;

  const DropdownModel({required this.key, required this.value});
}
