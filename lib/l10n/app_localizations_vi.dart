// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Hi Secure';

  @override
  String get securingPasswords => 'Đang bảo mật mật khẩu của bạn...';

  @override
  String get authenticateNow => 'Xác thực ngay';

  @override
  String get pressToUnlock => 'Nhấn nút xác thực để mở khóa ứng dụng';

  @override
  String get authentication => 'Xác thực';

  @override
  String get preparingAuthentication => 'Đang chuẩn bị xác thực...';

  @override
  String get systemWillChoose =>
      'Hệ thống sẽ tự động chọn phương thức xác thực phù hợp';

  @override
  String get authenticationSuccess => 'Xác thực thành công!';

  @override
  String get authenticationFailed => 'Xác thực thất bại hoặc chưa thiết lập';

  @override
  String get error => 'Lỗi';

  @override
  String get loggedOut => 'Đã đăng xuất';

  @override
  String get apps => 'Ứng dụng';

  @override
  String get noAppsYet => 'Chưa có ứng dụng nào';

  @override
  String get tapToAddFirst => 'Nhấn nút + để thêm ứng dụng đầu tiên';

  @override
  String get noUrlConfigured => 'Chưa cấu hình URL';

  @override
  String get editApp => 'Chỉnh sửa ứng dụng';

  @override
  String get settings => 'Cài đặt';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get securitySettings => 'Cài đặt bảo mật';

  @override
  String get managePasscodeAuth => 'Quản lý mật khẩu và xác thực';

  @override
  String get changePasscode => 'Thay đổi mật khẩu';

  @override
  String get updatePasscode => 'Cập nhật mật khẩu 6 số';

  @override
  String get passcodeChanged => 'Đã thay đổi mật khẩu thành công!';

  @override
  String get biometricAuthentication => 'Xác thực sinh trắc học';

  @override
  String get useFingerprintFaceId => 'Sử dụng vân tay hoặc Face ID';

  @override
  String get biometricEnabled => 'Đã bật xác thực sinh trắc học thành công!';

  @override
  String get failedToEnableBiometric => 'Không thể bật xác thực sinh trắc học';

  @override
  String get biometricDisabled => 'Đã tắt xác thực sinh trắc học';

  @override
  String get backupRestore => 'Sao lưu & Khôi phục';

  @override
  String get exportImportData => 'Xuất và nhập dữ liệu';

  @override
  String get exportData => 'Xuất dữ liệu';

  @override
  String get backupPasswordsSecurely => 'Sao lưu mật khẩu an toàn';

  @override
  String get importData => 'Nhập dữ liệu';

  @override
  String get restoreFromBackup => 'Khôi phục từ bản sao lưu';

  @override
  String get about => 'Giới thiệu';

  @override
  String get appInformationHelp => 'Thông tin ứng dụng và trợ giúp';

  @override
  String get helpSupport => 'Trợ giúp & Hỗ trợ';

  @override
  String get getHelpWithApp => 'Nhận trợ giúp với ứng dụng';

  @override
  String get privacyPolicy => 'Chính sách bảo mật';

  @override
  String get readPrivacyPolicy => 'Đọc chính sách bảo mật của chúng tôi';

  @override
  String get termsOfService => 'Điều khoản dịch vụ';

  @override
  String get readTermsOfService => 'Đọc điều khoản dịch vụ của chúng tôi';

  @override
  String get exportDataDescription =>
      'Nhập mật khẩu để mã hóa file sao lưu. Mật khẩu này sẽ được yêu cầu để khôi phục dữ liệu.';

  @override
  String get importDataDescription =>
      'Chọn file sao lưu và nhập mật khẩu đã dùng để mã hóa.';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get selectLanguage => 'Chọn ngôn ngữ ưa thích';

  @override
  String get english => 'Tiếng Anh';

  @override
  String get vietnamese => 'Tiếng Việt';
}
