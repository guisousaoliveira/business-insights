import '../response_model.dart';
import 'kit_model.dart';

class GetKitsResponseModel extends ResponseModel {
  static const _kitsKey = 'kits';

  final List<KitModel> kits;

  const GetKitsResponseModel({
    required super.total,
    required super.message,
    required this.kits,
  });

  factory GetKitsResponseModel.fromResponse(Map<String, dynamic> map) {
    final result =
        map[ResponseModel.resultKey] as Map<String, dynamic>? ?? const {};

    return GetKitsResponseModel(
      total: ResponseModel.totalFrom(map),
      message: ResponseModel.messageFrom(map),
      kits: (result[_kitsKey] as List? ?? const [])
          .map((e) => KitModel.fromResponse(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
