import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../constants/api_constants.dart';

part 'api_client.g.dart';

@RestApi()
abstract class ApiClient {
  factory ApiClient(Dio dio, {String? baseUrl}) = _ApiClient;

  // ==================== Auth ====================

  @POST(ApiConstants.authRegister)
  Future<HttpResponse<Map<String, dynamic>>> register(
    @Body() Map<String, dynamic> body,
  );

  @POST(ApiConstants.authLogin)
  Future<HttpResponse<Map<String, dynamic>>> login(
    @Body() Map<String, dynamic> body,
  );

  @POST(ApiConstants.authRefresh)
  Future<HttpResponse<Map<String, dynamic>>> refreshToken(
    @Body() Map<String, dynamic> body,
  );

  @POST(ApiConstants.authLogout)
  Future<HttpResponse<void>> logout();

  @POST(ApiConstants.authForgotPassword)
  Future<HttpResponse<void>> forgotPassword(
    @Body() Map<String, dynamic> body,
  );

  @POST(ApiConstants.authVerifyEmail)
  Future<HttpResponse<void>> verifyEmail(
    @Body() Map<String, dynamic> body,
  );

  @DELETE(ApiConstants.authDeleteAccount)
  Future<HttpResponse<void>> deleteAccount();

  // ==================== User ====================

  @GET(ApiConstants.usersMe)
  Future<HttpResponse<Map<String, dynamic>>> getProfile();

  @PATCH(ApiConstants.usersMe)
  Future<HttpResponse<Map<String, dynamic>>> updateProfile(
    @Body() Map<String, dynamic> body,
  );

  // Photo upload is handled directly via Firebase Storage
  // @PUT(ApiConstants.usersMePhoto)
  // Future<HttpResponse<Map<String, dynamic>>> uploadPhoto(...);

  @GET(ApiConstants.usersMeSettings)
  Future<HttpResponse<Map<String, dynamic>>> getSettings();

  @PATCH(ApiConstants.usersMeSettings)
  Future<HttpResponse<Map<String, dynamic>>> updateSettings(
    @Body() Map<String, dynamic> body,
  );

  // ==================== Business Cards ====================

  @GET(ApiConstants.cards)
  Future<HttpResponse<List<dynamic>>> getCards();

  @POST(ApiConstants.cards)
  Future<HttpResponse<Map<String, dynamic>>> createCard(
    @Body() Map<String, dynamic> body,
  );

  @GET('/cards/{id}')
  Future<HttpResponse<Map<String, dynamic>>> getCard(
    @Path('id') String id,
  );

  @PATCH('/cards/{id}')
  Future<HttpResponse<Map<String, dynamic>>> updateCard(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('/cards/{id}')
  Future<HttpResponse<void>> deleteCard(
    @Path('id') String id,
  );

  @POST('/cards/{id}/duplicate')
  Future<HttpResponse<Map<String, dynamic>>> duplicateCard(
    @Path('id') String id,
  );

  @GET('/cards/{id}/qr')
  Future<HttpResponse<Map<String, dynamic>>> getCardQr(
    @Path('id') String id,
  );

  @POST('/cards/{id}/wallet')
  Future<HttpResponse<Map<String, dynamic>>> addCardToWallet(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @GET('/cards/{id}/analytics')
  Future<HttpResponse<Map<String, dynamic>>> getCardAnalytics(
    @Path('id') String id,
  );

  @GET('/cards/public/{slug}')
  Future<HttpResponse<Map<String, dynamic>>> getPublicCard(
    @Path('slug') String slug,
  );

  // ==================== Templates ====================

  @GET(ApiConstants.templates)
  Future<HttpResponse<List<dynamic>>> getTemplates();

  @GET('/templates/{id}')
  Future<HttpResponse<Map<String, dynamic>>> getTemplate(
    @Path('id') String id,
  );

  // ==================== Tags History ====================

  @GET(ApiConstants.tags)
  Future<HttpResponse<List<dynamic>>> getTags(
    @Query('limit') int? limit,
    @Query('offset') int? offset,
  );

  @POST(ApiConstants.tags)
  Future<HttpResponse<Map<String, dynamic>>> saveTag(
    @Body() Map<String, dynamic> body,
  );

  @GET('/tags/{id}')
  Future<HttpResponse<Map<String, dynamic>>> getTag(
    @Path('id') String id,
  );

  @DELETE('/tags/{id}')
  Future<HttpResponse<void>> deleteTag(
    @Path('id') String id,
  );

  @POST('/tags/{id}/favorite')
  Future<HttpResponse<void>> toggleTagFavorite(
    @Path('id') String id,
  );

  @GET(ApiConstants.tagsExport)
  Future<HttpResponse<Map<String, dynamic>>> exportTags(
    @Query('format') String format,
  );

  // ==================== Write Templates ====================

  @GET(ApiConstants.writeTemplates)
  Future<HttpResponse<List<dynamic>>> getWriteTemplates();

  @POST(ApiConstants.writeTemplates)
  Future<HttpResponse<Map<String, dynamic>>> createWriteTemplate(
    @Body() Map<String, dynamic> body,
  );

  @GET('/write-templates/{id}')
  Future<HttpResponse<Map<String, dynamic>>> getWriteTemplate(
    @Path('id') String id,
  );

  @PATCH('/write-templates/{id}')
  Future<HttpResponse<Map<String, dynamic>>> updateWriteTemplate(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('/write-templates/{id}')
  Future<HttpResponse<void>> deleteWriteTemplate(
    @Path('id') String id,
  );

  // ==================== Subscription ====================

  @GET(ApiConstants.subscription)
  Future<HttpResponse<Map<String, dynamic>>> getSubscriptionStatus();

  @POST(ApiConstants.subscriptionVerify)
  Future<HttpResponse<Map<String, dynamic>>> verifyPurchase(
    @Body() Map<String, dynamic> body,
  );

  @POST(ApiConstants.subscriptionRestore)
  Future<HttpResponse<Map<String, dynamic>>> restorePurchase(
    @Body() Map<String, dynamic> body,
  );

  // ==================== Contacts ====================

  @GET(ApiConstants.contacts)
  Future<HttpResponse<List<dynamic>>> getContacts();

  @POST(ApiConstants.contacts)
  Future<HttpResponse<Map<String, dynamic>>> saveContact(
    @Body() Map<String, dynamic> body,
  );

  @GET('/contacts/{id}')
  Future<HttpResponse<Map<String, dynamic>>> getContact(
    @Path('id') String id,
  );

  @PATCH('/contacts/{id}')
  Future<HttpResponse<Map<String, dynamic>>> updateContact(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('/contacts/{id}')
  Future<HttpResponse<void>> deleteContact(
    @Path('id') String id,
  );

  @POST('/contacts/{id}/export')
  Future<HttpResponse<Map<String, dynamic>>> exportContact(
    @Path('id') String id,
  );
}
