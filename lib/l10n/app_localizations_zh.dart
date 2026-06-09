// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '智能门锁';

  @override
  String get smartLockPlatform => 'Smart Lock Platform';

  @override
  String get smartLockPlatformSub => '智能门锁管理平台';

  @override
  String get usernameOrEmail => '用户名 / 邮箱';

  @override
  String get password => '密码';

  @override
  String get pleaseInputUsername => '请输入用户名';

  @override
  String get pleaseInputPassword => '请输入密码';

  @override
  String get rememberMe => '记住我';

  @override
  String get login => '登录';

  @override
  String get language => '语言';

  @override
  String get my => '我的';

  @override
  String get keysManagement => '钥匙管理';

  @override
  String get locksManagement => '锁管理';

  @override
  String get account => '账号';

  @override
  String get version => '版本';

  @override
  String get currentTestHome => '当前测试主页';

  @override
  String get vendorSdkTest => '厂家 SDK 测试界面';

  @override
  String get onlineSwitchLock => '设置开关锁钥匙（在线）';

  @override
  String get keepOriginalTestFlow => '保留原有测试流程';

  @override
  String get logout => '退出登录';

  @override
  String get confirmLogout => '确认退出登录吗？';

  @override
  String get cancel => '取消';

  @override
  String get edit => '编辑';

  @override
  String get delete => '删除';

  @override
  String get deleteKeyTitle => '删除钥匙';

  @override
  String get deleteLockTitle => '删除锁';

  @override
  String confirmDeleteItem(Object name) {
    return '确认删除 $name 吗？';
  }

  @override
  String get logoutAction => '退出';

  @override
  String get cannotOpenCerebSite => '无法打开 Cereb.AI 官网';

  @override
  String get poweredBy => 'powered by';

  @override
  String get searchKeyHint => '搜索钥匙名称/编号';

  @override
  String get searchLockHint => '搜索锁名称/编号/位置';

  @override
  String get sessionExpired => '登录状态已失效，请重新登录';

  @override
  String get smartListEmpty => '暂无数据';

  @override
  String get smartListLoading => '加载中...';

  @override
  String get smartListNoMore => '没有更多了';

  @override
  String get unnamedDevice => '未命名';

  @override
  String get wizardConfirmStep => '确认完成';

  @override
  String get keyWizardCreateTitle => '新增钥匙（分步）';

  @override
  String get keyWizardEditTitle => '编辑钥匙（分步）';

  @override
  String get keyWizardFillRequired => '请先填写名称和编号';

  @override
  String get keyWizardSave => '保存';

  @override
  String get keyWizardNext => '下一步';

  @override
  String get keyWizardPrevious => '上一步';

  @override
  String get keyWizardStepConnect => '连接设备';

  @override
  String get keyWizardConnectHint => '扫描钥匙，选择 MAC 后连接并读取钥匙信息。';

  @override
  String get keyWizardScanning => '正在扫描钥匙...';

  @override
  String get keyWizardScanStarted => '扫描已开始，请等待设备列表刷新';

  @override
  String get keyWizardScanningShort => '扫描中';

  @override
  String get keyWizardScanKey => '扫描钥匙';

  @override
  String get keyWizardReadingInfo => '正在连接并读取钥匙信息...';

  @override
  String get keyWizardReadSuccess => '已读取钥匙信息';

  @override
  String get keyWizardReadFailed => '读取钥匙信息失败';

  @override
  String get keyWizardReadAction => '连接并读取钥匙信息';

  @override
  String get keyWizardStepInfo => '信息填写';

  @override
  String get keyWizardKeyName => '钥匙名称';

  @override
  String get keyWizardKeyNumber => '钥匙编号 / vendorKeyId';

  @override
  String get keyWizardKeyNumberHelper => '编辑时厂商编号不可修改';

  @override
  String get keyWizardKeyType => '钥匙类型';

  @override
  String get keyWizardOwnerId => '归属用户 ID';

  @override
  String get keyWizardOwnerIdHelper => '只表示保管人，不代表开锁权限';

  @override
  String get keyWizardStatus => '钥匙状态';

  @override
  String get keyWizardKeyNumberSummary => '钥匙编号';

  @override
  String get keyWizardTypeSummary => '类型';

  @override
  String get keyWizardOwnerSummary => '归属用户';

  @override
  String get keyWizardStatusSummary => '状态';

  @override
  String get lockWizardCreateTitle => '新增锁（分步）';

  @override
  String get lockWizardEditTitle => '编辑锁（分步）';

  @override
  String get lockWizardFillRequired => '请先填写名称、编号、位置';

  @override
  String get lockWizardConnectHint => '扫描钥匙，选择 MAC 后设置为采集锁号钥匙。';

  @override
  String get lockWizardPreparingCollector => '正在连接并设置采集锁号钥匙...';

  @override
  String get lockWizardCollectorReady => '采集钥匙已设置，请进入下一步后用钥匙碰目标锁';

  @override
  String get lockWizardPrepareFailed => '设置采集钥匙失败';

  @override
  String get lockWizardPrepareAction => '连接并设置采集锁号钥匙';

  @override
  String get lockWizardStepReadId => '读取锁号';

  @override
  String get lockWizardReadHint => '用已设置的钥匙碰目标锁，等待 onReport 回调中的 CMD=19 锁号。';

  @override
  String get lockWizardWaitingReport => '等待锁号回调，请用钥匙碰锁...';

  @override
  String get lockWizardParseFailed => '未从回调中解析到锁号';

  @override
  String get lockWizardReadSuccess => '已采集锁号';

  @override
  String get lockWizardReadFailed => '采集锁号失败';

  @override
  String get lockWizardReadAction => '等待并读取锁号';

  @override
  String get lockWizardLockNumber => '锁编号';

  @override
  String get lockWizardLockNumberHelper => '编辑时厂商锁号不可修改';

  @override
  String get lockWizardStepBasic => '基础信息';

  @override
  String get lockWizardLockName => '锁名称';

  @override
  String get lockWizardStepStatus => '状态设置';

  @override
  String get lockWizardSwitchState => '开关状态';

  @override
  String get lockWizardStepLocation => '位置信息';

  @override
  String get lockWizardLocation => '位置';

  @override
  String get lockWizardLockNameSummary => '锁名称';

  @override
  String get lockWizardLockNumberSummary => '锁编号';

  @override
  String get lockWizardLocationSummary => '位置';

  @override
  String get lockWizardSwitchStateSummary => '开关状态';

  @override
  String get keyStatusActive => '正常';

  @override
  String get listUpdatedAt => '更新时间';

  @override
  String get lockStateLocked => '已上锁';

  @override
  String get lockStateUnlocked => '已解锁';

  @override
  String get lockCardTapHint => '点击卡片进入开关锁控制';

  @override
  String get lockControlTitle => '锁控制';

  @override
  String get lockControlSelectMacFirst => '请先扫描并选择钥匙 MAC';

  @override
  String get lockControlUnlockSubmitted => '开锁指令已提交';

  @override
  String get lockControlLockSubmitted => '关锁指令已提交';

  @override
  String get lockControlFailed => '控制失败';

  @override
  String get lockControlCurrentStatus => '当前状态';

  @override
  String get lockControlSdkConfig => 'SDK 控制配置';

  @override
  String lockControlKeyCount(Object count) {
    return '$count 台钥匙';
  }

  @override
  String get lockControlStopScan => '停止扫描';

  @override
  String get lockControlKeyMac => '钥匙 MAC';

  @override
  String get lockControlUnlockAction => '开锁';

  @override
  String get lockControlLockAction => '关锁';
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizationsZh {
  AppLocalizationsZhHans(): super('zh_Hans');

  @override
  String get appTitle => '智能门锁';

  @override
  String get smartLockPlatform => 'Smart Lock Platform';

  @override
  String get smartLockPlatformSub => '智能门锁管理平台';

  @override
  String get usernameOrEmail => '用户名 / 邮箱';

  @override
  String get password => '密码';

  @override
  String get pleaseInputUsername => '请输入用户名';

  @override
  String get pleaseInputPassword => '请输入密码';

  @override
  String get rememberMe => '记住我';

  @override
  String get login => '登录';

  @override
  String get language => '语言';

  @override
  String get my => '我的';

  @override
  String get keysManagement => '钥匙管理';

  @override
  String get locksManagement => '锁管理';

  @override
  String get account => '账号';

  @override
  String get version => '版本';

  @override
  String get currentTestHome => '当前测试主页';

  @override
  String get vendorSdkTest => '厂家 SDK 测试界面';

  @override
  String get onlineSwitchLock => '设置开关锁钥匙（在线）';

  @override
  String get keepOriginalTestFlow => '保留原有测试流程';

  @override
  String get logout => '退出登录';

  @override
  String get confirmLogout => '确认退出登录吗？';

  @override
  String get cancel => '取消';

  @override
  String get edit => '编辑';

  @override
  String get delete => '删除';

  @override
  String get deleteKeyTitle => '删除钥匙';

  @override
  String get deleteLockTitle => '删除锁';

  @override
  String confirmDeleteItem(Object name) {
    return '确认删除 $name 吗？';
  }

  @override
  String get logoutAction => '退出';

  @override
  String get cannotOpenCerebSite => '无法打开 Cereb.AI 官网';

  @override
  String get poweredBy => 'powered by';

  @override
  String get searchKeyHint => '搜索钥匙名称/编号';

  @override
  String get searchLockHint => '搜索锁名称/编号/位置';

  @override
  String get sessionExpired => '登录状态已失效，请重新登录';

  @override
  String get smartListEmpty => '暂无数据';

  @override
  String get smartListLoading => '加载中...';

  @override
  String get smartListNoMore => '没有更多了';

  @override
  String get unnamedDevice => '未命名';

  @override
  String get wizardConfirmStep => '确认完成';

  @override
  String get keyWizardCreateTitle => '新增钥匙（分步）';

  @override
  String get keyWizardEditTitle => '编辑钥匙（分步）';

  @override
  String get keyWizardFillRequired => '请先填写名称和编号';

  @override
  String get keyWizardSave => '保存';

  @override
  String get keyWizardNext => '下一步';

  @override
  String get keyWizardPrevious => '上一步';

  @override
  String get keyWizardStepConnect => '连接设备';

  @override
  String get keyWizardConnectHint => '扫描钥匙，选择 MAC 后连接并读取钥匙信息。';

  @override
  String get keyWizardScanning => '正在扫描钥匙...';

  @override
  String get keyWizardScanStarted => '扫描已开始，请等待设备列表刷新';

  @override
  String get keyWizardScanningShort => '扫描中';

  @override
  String get keyWizardScanKey => '扫描钥匙';

  @override
  String get keyWizardReadingInfo => '正在连接并读取钥匙信息...';

  @override
  String get keyWizardReadSuccess => '已读取钥匙信息';

  @override
  String get keyWizardReadFailed => '读取钥匙信息失败';

  @override
  String get keyWizardReadAction => '连接并读取钥匙信息';

  @override
  String get keyWizardStepInfo => '信息填写';

  @override
  String get keyWizardKeyName => '钥匙名称';

  @override
  String get keyWizardKeyNumber => '钥匙编号 / vendorKeyId';

  @override
  String get keyWizardKeyNumberHelper => '编辑时厂商编号不可修改';

  @override
  String get keyWizardKeyType => '钥匙类型';

  @override
  String get keyWizardOwnerId => '归属用户 ID';

  @override
  String get keyWizardOwnerIdHelper => '只表示保管人，不代表开锁权限';

  @override
  String get keyWizardStatus => '钥匙状态';

  @override
  String get keyWizardKeyNumberSummary => '钥匙编号';

  @override
  String get keyWizardTypeSummary => '类型';

  @override
  String get keyWizardOwnerSummary => '归属用户';

  @override
  String get keyWizardStatusSummary => '状态';

  @override
  String get lockWizardCreateTitle => '新增锁（分步）';

  @override
  String get lockWizardEditTitle => '编辑锁（分步）';

  @override
  String get lockWizardFillRequired => '请先填写名称、编号、位置';

  @override
  String get lockWizardConnectHint => '扫描钥匙，选择 MAC 后设置为采集锁号钥匙。';

  @override
  String get lockWizardPreparingCollector => '正在连接并设置采集锁号钥匙...';

  @override
  String get lockWizardCollectorReady => '采集钥匙已设置，请进入下一步后用钥匙碰目标锁';

  @override
  String get lockWizardPrepareFailed => '设置采集钥匙失败';

  @override
  String get lockWizardPrepareAction => '连接并设置采集锁号钥匙';

  @override
  String get lockWizardStepReadId => '读取锁号';

  @override
  String get lockWizardReadHint => '用已设置的钥匙碰目标锁，等待 onReport 回调中的 CMD=19 锁号。';

  @override
  String get lockWizardWaitingReport => '等待锁号回调，请用钥匙碰锁...';

  @override
  String get lockWizardParseFailed => '未从回调中解析到锁号';

  @override
  String get lockWizardReadSuccess => '已采集锁号';

  @override
  String get lockWizardReadFailed => '采集锁号失败';

  @override
  String get lockWizardReadAction => '等待并读取锁号';

  @override
  String get lockWizardLockNumber => '锁编号';

  @override
  String get lockWizardLockNumberHelper => '编辑时厂商锁号不可修改';

  @override
  String get lockWizardStepBasic => '基础信息';

  @override
  String get lockWizardLockName => '锁名称';

  @override
  String get lockWizardStepStatus => '状态设置';

  @override
  String get lockWizardSwitchState => '开关状态';

  @override
  String get lockWizardStepLocation => '位置信息';

  @override
  String get lockWizardLocation => '位置';

  @override
  String get lockWizardLockNameSummary => '锁名称';

  @override
  String get lockWizardLockNumberSummary => '锁编号';

  @override
  String get lockWizardLocationSummary => '位置';

  @override
  String get lockWizardSwitchStateSummary => '开关状态';

  @override
  String get keyStatusActive => '正常';

  @override
  String get listUpdatedAt => '更新时间';

  @override
  String get lockStateLocked => '已上锁';

  @override
  String get lockStateUnlocked => '已解锁';

  @override
  String get lockCardTapHint => '点击卡片进入开关锁控制';

  @override
  String get lockControlTitle => '锁控制';

  @override
  String get lockControlSelectMacFirst => '请先扫描并选择钥匙 MAC';

  @override
  String get lockControlUnlockSubmitted => '开锁指令已提交';

  @override
  String get lockControlLockSubmitted => '关锁指令已提交';

  @override
  String get lockControlFailed => '控制失败';

  @override
  String get lockControlCurrentStatus => '当前状态';

  @override
  String get lockControlSdkConfig => 'SDK 控制配置';

  @override
  String lockControlKeyCount(Object count) {
    return '$count 台钥匙';
  }

  @override
  String get lockControlStopScan => '停止扫描';

  @override
  String get lockControlKeyMac => '钥匙 MAC';

  @override
  String get lockControlUnlockAction => '开锁';

  @override
  String get lockControlLockAction => '关锁';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant(): super('zh_Hant');

  @override
  String get appTitle => '智慧門鎖';

  @override
  String get smartLockPlatform => 'Smart Lock Platform';

  @override
  String get smartLockPlatformSub => '智慧門鎖管理平台';

  @override
  String get usernameOrEmail => '使用者名稱 / 郵箱';

  @override
  String get password => '密碼';

  @override
  String get pleaseInputUsername => '請輸入使用者名稱';

  @override
  String get pleaseInputPassword => '請輸入密碼';

  @override
  String get rememberMe => '記住我';

  @override
  String get login => '登入';

  @override
  String get language => '語言';

  @override
  String get my => '我的';

  @override
  String get keysManagement => '鑰匙管理';

  @override
  String get locksManagement => '鎖管理';

  @override
  String get account => '帳號';

  @override
  String get version => '版本';

  @override
  String get currentTestHome => '目前測試首頁';

  @override
  String get vendorSdkTest => '廠家 SDK 測試介面';

  @override
  String get onlineSwitchLock => '設定開關鎖鑰匙（線上）';

  @override
  String get keepOriginalTestFlow => '保留原有測試流程';

  @override
  String get logout => '登出';

  @override
  String get confirmLogout => '確認要登出嗎？';

  @override
  String get cancel => '取消';

  @override
  String get edit => '編輯';

  @override
  String get delete => '刪除';

  @override
  String get deleteKeyTitle => '刪除鑰匙';

  @override
  String get deleteLockTitle => '刪除鎖';

  @override
  String confirmDeleteItem(Object name) {
    return '確認刪除 $name 嗎？';
  }

  @override
  String get logoutAction => '登出';

  @override
  String get cannotOpenCerebSite => '無法開啟 Cereb.AI 官網';

  @override
  String get poweredBy => 'powered by';

  @override
  String get searchKeyHint => '搜尋鑰匙名稱/編號';

  @override
  String get searchLockHint => '搜尋鎖名稱/編號/位置';

  @override
  String get sessionExpired => '登入狀態已失效，請重新登入';

  @override
  String get smartListEmpty => '暫無資料';

  @override
  String get smartListLoading => '載入中...';

  @override
  String get smartListNoMore => '沒有更多了';

  @override
  String get unnamedDevice => '未命名';

  @override
  String get wizardConfirmStep => '確認完成';

  @override
  String get keyWizardCreateTitle => '新增鑰匙（分步）';

  @override
  String get keyWizardEditTitle => '編輯鑰匙（分步）';

  @override
  String get keyWizardFillRequired => '請先填寫名稱和編號';

  @override
  String get keyWizardSave => '儲存';

  @override
  String get keyWizardNext => '下一步';

  @override
  String get keyWizardPrevious => '上一步';

  @override
  String get keyWizardStepConnect => '連接設備';

  @override
  String get keyWizardConnectHint => '掃描鑰匙，選擇 MAC 後連接並讀取鑰匙資訊。';

  @override
  String get keyWizardScanning => '正在掃描鑰匙...';

  @override
  String get keyWizardScanStarted => '掃描已開始，請等待設備列表更新';

  @override
  String get keyWizardScanningShort => '掃描中';

  @override
  String get keyWizardScanKey => '掃描鑰匙';

  @override
  String get keyWizardReadingInfo => '正在連接並讀取鑰匙資訊...';

  @override
  String get keyWizardReadSuccess => '已讀取鑰匙資訊';

  @override
  String get keyWizardReadFailed => '讀取鑰匙資訊失敗';

  @override
  String get keyWizardReadAction => '連接並讀取鑰匙資訊';

  @override
  String get keyWizardStepInfo => '資訊填寫';

  @override
  String get keyWizardKeyName => '鑰匙名稱';

  @override
  String get keyWizardKeyNumber => '鑰匙編號 / vendorKeyId';

  @override
  String get keyWizardKeyNumberHelper => '編輯時廠商編號不可修改';

  @override
  String get keyWizardKeyType => '鑰匙類型';

  @override
  String get keyWizardOwnerId => '歸屬用戶 ID';

  @override
  String get keyWizardOwnerIdHelper => '僅表示保管人，不代表開鎖權限';

  @override
  String get keyWizardStatus => '鑰匙狀態';

  @override
  String get keyWizardKeyNumberSummary => '鑰匙編號';

  @override
  String get keyWizardTypeSummary => '類型';

  @override
  String get keyWizardOwnerSummary => '歸屬用戶';

  @override
  String get keyWizardStatusSummary => '狀態';

  @override
  String get lockWizardCreateTitle => '新增鎖（分步）';

  @override
  String get lockWizardEditTitle => '編輯鎖（分步）';

  @override
  String get lockWizardFillRequired => '請先填寫名稱、編號、位置';

  @override
  String get lockWizardConnectHint => '掃描鑰匙，選擇 MAC 後設置為採集鎖號鑰匙。';

  @override
  String get lockWizardPreparingCollector => '正在連接並設置採集鎖號鑰匙...';

  @override
  String get lockWizardCollectorReady => '採集鑰匙已設置，請進入下一步後用鑰匙碰目標鎖';

  @override
  String get lockWizardPrepareFailed => '設置採集鑰匙失敗';

  @override
  String get lockWizardPrepareAction => '連接並設置採集鎖號鑰匙';

  @override
  String get lockWizardStepReadId => '讀取鎖號';

  @override
  String get lockWizardReadHint => '用已設置的鑰匙碰目標鎖，等待 onReport 回調中的 CMD=19 鎖號。';

  @override
  String get lockWizardWaitingReport => '等待鎖號回調，請用鑰匙碰鎖...';

  @override
  String get lockWizardParseFailed => '未從回調中解析到鎖號';

  @override
  String get lockWizardReadSuccess => '已採集鎖號';

  @override
  String get lockWizardReadFailed => '採集鎖號失敗';

  @override
  String get lockWizardReadAction => '等待並讀取鎖號';

  @override
  String get lockWizardLockNumber => '鎖編號';

  @override
  String get lockWizardLockNumberHelper => '編輯時廠商鎖號不可修改';

  @override
  String get lockWizardStepBasic => '基礎資訊';

  @override
  String get lockWizardLockName => '鎖名稱';

  @override
  String get lockWizardStepStatus => '狀態設置';

  @override
  String get lockWizardSwitchState => '開關狀態';

  @override
  String get lockWizardStepLocation => '位置信息';

  @override
  String get lockWizardLocation => '位置';

  @override
  String get lockWizardLockNameSummary => '鎖名稱';

  @override
  String get lockWizardLockNumberSummary => '鎖編號';

  @override
  String get lockWizardLocationSummary => '位置';

  @override
  String get lockWizardSwitchStateSummary => '開關狀態';

  @override
  String get keyStatusActive => '正常';

  @override
  String get listUpdatedAt => '更新時間';

  @override
  String get lockStateLocked => '已上鎖';

  @override
  String get lockStateUnlocked => '已解鎖';

  @override
  String get lockCardTapHint => '點擊卡片進入開關鎖控制';

  @override
  String get lockControlTitle => '鎖控制';

  @override
  String get lockControlSelectMacFirst => '請先掃描並選擇鑰匙 MAC';

  @override
  String get lockControlUnlockSubmitted => '開鎖指令已提交';

  @override
  String get lockControlLockSubmitted => '關鎖指令已提交';

  @override
  String get lockControlFailed => '控制失敗';

  @override
  String get lockControlCurrentStatus => '當前狀態';

  @override
  String get lockControlSdkConfig => 'SDK 控制配置';

  @override
  String lockControlKeyCount(Object count) {
    return '$count 台鑰匙';
  }

  @override
  String get lockControlStopScan => '停止掃描';

  @override
  String get lockControlKeyMac => '鑰匙 MAC';

  @override
  String get lockControlUnlockAction => '開鎖';

  @override
  String get lockControlLockAction => '關鎖';
}
