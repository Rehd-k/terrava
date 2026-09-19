import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:terrava/core/network/api_exception.dart';
import 'package:terrava/features/listings/data/geocoding_repository.dart';
import 'package:terrava/features/listings/data/listing_models.dart';
import 'package:terrava/features/listings/data/listings_repository.dart';
import 'package:terrava/features/listings/data/media_repository.dart';

class DraftPhoto {
  const DraftPhoto({
    required this.key,
    this.localPath,
    this.mediaId,
    this.url,
    this.sortOrder = 0,
    this.uploading = false,
    this.error,
  });

  final String key;
  final String? localPath;
  final String? mediaId;
  final String? url;
  final int sortOrder;
  final bool uploading;
  final String? error;

  bool get isRemote => mediaId != null && url != null;

  DraftPhoto copyWith({
    String? localPath,
    String? mediaId,
    String? url,
    int? sortOrder,
    bool? uploading,
    String? error,
    bool clearError = false,
  }) {
    return DraftPhoto(
      key: key,
      localPath: localPath ?? this.localPath,
      mediaId: mediaId ?? this.mediaId,
      url: url ?? this.url,
      sortOrder: sortOrder ?? this.sortOrder,
      uploading: uploading ?? this.uploading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CreateListingState {
  const CreateListingState({
    this.step = 0,
    this.propertyType = 'LAND',
    this.transactionType = 'SALE',
    this.latitude,
    this.longitude,
    this.address,
    this.city,
    this.state,
    this.country,
    this.addressLabel,
    this.editingAddress = false,
    this.bedrooms = 1,
    this.bathrooms = 1,
    this.propertySize,
    this.landSize,
    this.price = 0,
    this.agencyFee,
    this.legalFee,
    this.listedBy = 'OWNER',
    this.currency = 'NGN',
    this.description = '',
    this.title,
    this.listingId,
    this.propertyId,
    this.photos = const [],
    this.saving = false,
    this.submitting = false,
    this.loadingExisting = false,
    this.error,
  });

  final int step;
  final String propertyType;
  final String transactionType;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? addressLabel;
  final bool editingAddress;
  final int bedrooms;
  final double bathrooms;
  final double? propertySize;
  final double? landSize;
  final double price;
  final double? agencyFee;
  final double? legalFee;
  final String listedBy;
  final String currency;
  final String description;
  final String? title;
  final String? listingId;
  final String? propertyId;
  final List<DraftPhoto> photos;
  final bool saving;
  final bool submitting;
  final bool loadingExisting;
  final String? error;

  bool get hasPin => latitude != null && longitude != null;
  bool get isLand => propertyType == 'LAND';
  bool get isRental => transactionType == 'RENT' || transactionType == 'LEASE';
  String get pricePeriod => isRental ? 'PER_YEAR' : 'ONE_OFF';
  bool get canContinueStep1 =>
      propertyType.isNotEmpty && transactionType.isNotEmpty;
  bool get canContinueStep2 => hasPin;
  bool get hasCoverPhoto =>
      photos.any((p) => p.url != null || p.localPath != null);
  bool get canSubmit =>
      hasPin &&
      price > 0 &&
      photos.any((p) => p.mediaId != null) &&
      !photos.any((p) => p.uploading);

  CreateListingState copyWith({
    int? step,
    String? propertyType,
    String? transactionType,
    double? latitude,
    double? longitude,
    String? address,
    String? city,
    String? state,
    String? country,
    String? addressLabel,
    bool? editingAddress,
    int? bedrooms,
    double? bathrooms,
    double? propertySize,
    double? landSize,
    double? price,
    double? agencyFee,
    double? legalFee,
    String? listedBy,
    String? currency,
    String? description,
    String? title,
    String? listingId,
    String? propertyId,
    List<DraftPhoto>? photos,
    bool? saving,
    bool? submitting,
    bool? loadingExisting,
    String? error,
    bool clearError = false,
    bool clearTitle = false,
  }) {
    return CreateListingState(
      step: step ?? this.step,
      propertyType: propertyType ?? this.propertyType,
      transactionType: transactionType ?? this.transactionType,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      addressLabel: addressLabel ?? this.addressLabel,
      editingAddress: editingAddress ?? this.editingAddress,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      propertySize: propertySize ?? this.propertySize,
      landSize: landSize ?? this.landSize,
      price: price ?? this.price,
      agencyFee: agencyFee ?? this.agencyFee,
      legalFee: legalFee ?? this.legalFee,
      listedBy: listedBy ?? this.listedBy,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      title: clearTitle ? null : (title ?? this.title),
      listingId: listingId ?? this.listingId,
      propertyId: propertyId ?? this.propertyId,
      photos: photos ?? this.photos,
      saving: saving ?? this.saving,
      submitting: submitting ?? this.submitting,
      loadingExisting: loadingExisting ?? this.loadingExisting,
      error: clearError ? null : (error ?? this.error),
    );
  }

  Map<String, dynamic> toWriteBody() {
    return {
      'type': propertyType,
      'transactionType': transactionType,
      'latitude': latitude,
      'longitude': longitude,
      'price': price,
      'agencyFee': agencyFee,
      'legalFee': legalFee,
      'listedBy': listedBy,
      'pricePeriod': pricePeriod,
      'currency': currency,
      if (title != null && title!.trim().isNotEmpty) 'title': title!.trim(),
      if (description.trim().isNotEmpty) 'description': description.trim(),
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (country != null) 'country': country,
      if (propertySize != null) 'propertySize': propertySize,
      if (landSize != null) 'landSize': landSize,
      'bedrooms': isLand ? null : bedrooms,
      'bathrooms': isLand ? null : bathrooms,
    };
  }
}

class CreateListingNotifier extends Notifier<CreateListingState> {
  @override
  CreateListingState build() => const CreateListingState();

  ListingsRepository get _listings => ref.read(listingsRepositoryProvider);
  MediaRepository get _media => ref.read(mediaRepositoryProvider);
  GeocodingRepository get _geocode => ref.read(geocodingRepositoryProvider);

  void setStep(int step) {
    state = state.copyWith(step: step.clamp(0, 2), clearError: true);
  }

  void setPropertyType(String type) {
    state = state.copyWith(propertyType: type, clearError: true);
  }

  void setTransactionType(String type) {
    state = state.copyWith(transactionType: type, clearError: true);
  }

  void setPin(double latitude, double longitude) {
    state = state.copyWith(latitude: latitude, longitude: longitude);
  }

  void setEditingAddress(bool value) {
    state = state.copyWith(editingAddress: value);
  }

  void setAddressFields({
    String? address,
    String? city,
    String? state,
    String? country,
  }) {
    this.state = this.state.copyWith(
      address: address,
      city: city,
      state: state,
      country: country,
    );
  }

  void setBedrooms(int value) {
    state = state.copyWith(bedrooms: value.clamp(0, 20));
  }

  void setBathrooms(double value) {
    state = state.copyWith(bathrooms: value.clamp(0, 15));
  }

  void setPropertySize(double? value) {
    state = state.copyWith(propertySize: value);
  }

  void setLandSize(double? value) {
    state = state.copyWith(landSize: value);
  }

  void setPrice(double value) {
    state = state.copyWith(price: value < 0 ? 0 : value);
  }

  void setAgencyFee(double? value) {
    state = state.copyWith(agencyFee: value);
  }

  void setLegalFee(double? value) {
    state = state.copyWith(legalFee: value);
  }

  void setListedBy(String value) {
    state = state.copyWith(listedBy: value);
  }

  void setDescription(String value) {
    state = state.copyWith(description: value);
  }

  Future<void> reverseGeocode(double latitude, double longitude) async {
    state = state.copyWith(latitude: latitude, longitude: longitude);
    final result = await _geocode.reverse(
      latitude: latitude,
      longitude: longitude,
    );
    if (result == null) return;
    if (state.editingAddress) return;
    state = state.copyWith(
      address: result.address,
      city: result.city,
      state: result.state,
      country: result.country,
      addressLabel: result.label,
    );
  }

  void reset() {
    state = const CreateListingState();
  }

  Future<void> loadExisting(String id) async {
    state = state.copyWith(loadingExisting: true, clearError: true);
    try {
      final listing = await _listings.fetchMineById(id);
      final photos = listing.media.where((m) => m.mediaType == 'IMAGE').toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      state = CreateListingState(
        step: 0,
        propertyType: listing.property.type,
        transactionType: listing.transactionType,
        latitude: listing.property.latitude,
        longitude: listing.property.longitude,
        address: listing.property.address,
        city: listing.property.city,
        state: listing.property.state,
        country: listing.property.country,
        bedrooms: listing.property.bedrooms ?? 1,
        bathrooms: listing.property.bathrooms ?? 1,
        propertySize: listing.property.propertySize,
        landSize: listing.property.landSize,
        price: listing.price,
        agencyFee: listing.agencyFee,
        legalFee: listing.legalFee,
        listedBy: listing.listedBy,
        currency: listing.currency,
        description: listing.description ?? listing.property.description ?? '',
        title: listing.title,
        listingId: listing.id,
        propertyId: listing.property.id,
        photos: [
          for (var i = 0; i < photos.length; i++)
            DraftPhoto(
              key: photos[i].id,
              mediaId: photos[i].id,
              url: photos[i].url,
              sortOrder: photos[i].sortOrder,
            ),
        ],
      );
    } catch (error) {
      state = state.copyWith(
        loadingExisting: false,
        error: error is ApiException
            ? error.message
            : 'Could not load listing.',
      );
    }
  }

  Future<bool> persistDraft() async {
    if (!state.hasPin) return false;
    state = state.copyWith(saving: true, clearError: true);
    try {
      final ListingDetail saved;
      if (state.listingId == null) {
        saved = await _listings.createListing(state.toWriteBody());
      } else {
        saved = await _listings.updateListing(
          state.listingId!,
          state.toWriteBody(),
        );
      }
      state = state.copyWith(
        listingId: saved.id,
        propertyId: saved.property.id,
        title: saved.title,
        saving: false,
      );
      await _uploadPendingPhotos();
      return true;
    } catch (error) {
      state = state.copyWith(
        saving: false,
        error: error is ApiException ? error.message : 'Could not save draft.',
      );
      return false;
    }
  }

  Future<bool> goNext() async {
    if (state.step == 0) {
      if (!state.canContinueStep1) return false;
      setStep(1);
      return true;
    }
    if (state.step == 1) {
      if (!state.canContinueStep2) {
        state = state.copyWith(error: 'Drop a pin on the map first.');
        return false;
      }
      final saved = await persistDraft();
      if (!saved) return false;
      setStep(2);
      return true;
    }
    return submit();
  }

  void goBack() {
    if (state.step > 0) setStep(state.step - 1);
  }

  Future<bool> saveAndExit() async {
    if (!state.hasPin) return true;
    return persistDraft();
  }

  Future<void> pickPhotos() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 92);
    if (files.isEmpty) return;

    final remaining = 20 - state.photos.length;
    if (remaining <= 0) {
      state = state.copyWith(error: 'You can add up to 20 photos.');
      return;
    }

    final additions = <DraftPhoto>[];
    for (var i = 0; i < files.length && i < remaining; i++) {
      additions.add(
        DraftPhoto(
          key: '${DateTime.now().microsecondsSinceEpoch}-$i',
          localPath: files[i].path,
          sortOrder: state.photos.length + i,
          uploading: state.listingId != null,
        ),
      );
    }
    state = state.copyWith(photos: [...state.photos, ...additions]);
    if (state.listingId != null) {
      await _uploadPendingPhotos();
    }
  }

  Future<void> removePhoto(String key) async {
    final index = state.photos.indexWhere((p) => p.key == key);
    if (index < 0) return;
    final photo = state.photos[index];
    if (photo.mediaId != null) {
      try {
        await _media.delete(photo.mediaId!);
      } catch (error) {
        state = state.copyWith(
          error: error is ApiException
              ? error.message
              : 'Could not remove photo.',
        );
        return;
      }
    }
    final next = [
      for (final item in state.photos)
        if (item.key != key) item,
    ];
    state = state.copyWith(
      photos: [
        for (var i = 0; i < next.length; i++) next[i].copyWith(sortOrder: i),
      ],
    );
  }

  Future<bool> submit() async {
    if (state.listingId == null) {
      final saved = await persistDraft();
      if (!saved) return false;
    } else {
      final saved = await persistDraft();
      if (!saved) return false;
    }
    if (!state.canSubmit) {
      state = state.copyWith(
        error: state.price <= 0
            ? 'Set an asking price before submitting.'
            : 'Add at least one photo before submitting.',
      );
      return false;
    }
    state = state.copyWith(submitting: true, clearError: true);
    try {
      await _listings.submitListing(state.listingId!);
      state = state.copyWith(submitting: false);
      return true;
    } catch (error) {
      state = state.copyWith(
        submitting: false,
        error: error is ApiException
            ? error.message
            : 'Could not submit listing.',
      );
      return false;
    }
  }

  Future<void> _uploadPendingPhotos() async {
    final listingId = state.listingId;
    if (listingId == null) return;

    for (final photo in [...state.photos]) {
      if (photo.mediaId != null || photo.localPath == null) continue;
      _setPhoto(photo.key, photo.copyWith(uploading: true, clearError: true));
      try {
        final auth = await _media.fetchAuth();
        List<int> compressed;
        try {
          compressed =
              await FlutterImageCompress.compressWithFile(
                photo.localPath!,
                quality: 82,
                minWidth: 1600,
                minHeight: 1600,
              ) ??
              await XFile(photo.localPath!).readAsBytes();
        } catch (_) {
          compressed = await XFile(photo.localPath!).readAsBytes();
        }
        final uploaded = await _media.uploadToImageKit(
          bytes: compressed,
          fileName: 'listing-${photo.sortOrder}.jpg',
          auth: auth,
        );
        final saved = await _media.persist(
          uploaded: uploaded,
          listingId: listingId,
          sortOrder: photo.sortOrder,
        );
        _setPhoto(
          photo.key,
          photo.copyWith(
            mediaId: saved.id,
            url: saved.url,
            uploading: false,
            clearError: true,
          ),
        );
      } catch (error) {
        _setPhoto(
          photo.key,
          photo.copyWith(
            uploading: false,
            error: error is ApiException ? error.message : 'Upload failed',
          ),
        );
      }
    }
  }

  void _setPhoto(String key, DraftPhoto next) {
    state = state.copyWith(
      photos: [
        for (final photo in state.photos)
          if (photo.key == key) next else photo,
      ],
    );
  }
}

final createListingProvider =
    NotifierProvider<CreateListingNotifier, CreateListingState>(
      CreateListingNotifier.new,
    );
