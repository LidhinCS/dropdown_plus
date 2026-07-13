/// Returns `true` when online. When [checkInternetConnection] is null, assumes online.
Future<bool> dropdownHasInternet(
  Future<bool> Function()? checkInternetConnection,
) async =>
    checkInternetConnection == null ? true : await checkInternetConnection();
