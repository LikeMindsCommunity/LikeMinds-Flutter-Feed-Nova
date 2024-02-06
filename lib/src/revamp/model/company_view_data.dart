class LMCompanyViewData {
  final String id;
  String? name;
  String? imageUrl;
  String? description;

  LMCompanyViewData._({
    required this.id,
    this.name,
    this.imageUrl,
    this.description,
  });
}

class LMCompanyViewDataBuilder {
  String? _id;
  String? _name;
  String? _imageUrl;
  String? _description;

  void id(String id) {
    _id = id;
  }

  void name(String name) {
    _name = name;
  }

  void imageUrl(String imageUrl) {
    _imageUrl = imageUrl;
  }

  void description(String description) {
    _description = description;
  }

  LMCompanyViewData build() {
    if (_id == null) {
      throw Exception('id is required');
    }
    return LMCompanyViewData._(
      id: _id!,
      name: _name,
      imageUrl: _imageUrl,
      description: _description,
    );
  }
}
