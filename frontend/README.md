# 뱅크드레싱 Frontend (Flutter)

뱅크샐러드 엑셀 데이터를 업로드해서 거래내역/과소비 패턴을 보는 Flutter 앱입니다.

---

## 1. 폴더 구조

lib/
├─ core/             # 공통 인프라 레이어
│  ├─ api/
│  │  ├─ api_client.dart    # BaseApiClient: HTTP 공통 처리
│  │  └─ api_config.dart    # API baseUrl, timeout, 환경 분기
│  ├─ logger/
│  │  └─ logger_service.dart
│  ├─ notification/
│  │  └─ fcm_service.dart   # FCM (모바일 알림)
│  ├─ utils/
│  │  └─ device/
│  │     └─ app_launcher_service.dart  # 뱅크샐러드 앱/스토어 열기
│  └─ widgets/ (공용 위젯 자리, 필요 시 사용)
│
├─ domains/          # 도메인별 기능 모듈
│  ├─ home/
│  │  └─ home_screen.dart
│  ├─ upload/
│  │  ├─ upload_api.dart
│  │  ├─ upload_file_validator.dart          # 모바일 검증
│  │  ├─ upload_file_validator_stub.dart     # 웹용 stub
│  │  └─ widgets/excel_upload_button.dart
│  ├─ transaction/
│  │  ├─ transaction.dart                    # 거래 모델
│  │  ├─ transaction_api.dart                # 거래 조회 API
│  │  ├─ stats_api.dart                      # 월별 통계 API
│  │  ├─ transactions_screen.dart            # 거래 목록
│  │  ├─ transaction_detail_screen.dart      # 거래 상세
│  │  ├─ utils/category_icons.dart           # 카테고리 아이콘
│  │  └─ widgets/...(month_selector 등)
│  ├─ analysis/
│  │  ├─ overspending_pattern.dart           # 과소비 패턴 모델
│  │  ├─ analysis_api.dart                   # 과소비 분석/규칙 API
│  │  ├─ overspending_screen.dart            # 과소비 분석 화면
│  │  └─ overspending_rules_screen.dart      # 과소비 규칙 CRUD 화면
│  └─ auth, user/ (향후 확장용)
│
└─ main.dart---

## 2. 화면 흐름

앱 진입 구조:

- `main.dart`
  - `MyApp` → `MainNavigationPage` (하단 3탭 네비게이션)
    - 탭 0: `HomeScreen` (홈)
    - 탭 1: `TransactionsScreen` (거래내역)
    - 탭 2: `OverspendingScreen` (과소비 분석)

각 화면 역할:

- **HomeScreen**
  - 뱅크샐러드 앱/플레이스토어 열기 (`AppLauncherService`)
  - 엑셀 업로드 버튼 (`ExcelUploadButton`)

- **TransactionsScreen**
  - 선택한 연/월에 대한 거래 목록 표시
  - 무한 스크롤, 월별 통계 카드, 거래 상세 화면으로 이동

- **OverspendingScreen**
  - 선택한 연/월의 과소비 패턴 리스트 표시
  - “규칙 관리” 화면으로 이동 버튼

- **OverspendingRulesScreen**
  - 과소비 규칙 목록 조회
  - 규칙 추가/수정/삭제 (CRUD)

---

## 3. 데이터 / API 흐름

### 공통 HTTP 레이어

- `core/api/api_client.dart` (`BaseApiClient`)
  - `get / post / put / delete / postMultipart / postMultipartBytes`
  - 공통: URL 조합, timeout, JSON 파싱, 로깅, 에러 처리

- `core/api/api_config.dart`
  - `kDebugMode` 기준으로
    - 개발: `http://10.0.2.2:8000`
    - 배포: `https://banksalad-backend.up.railway.app`
  - `--dart-define=API_URL=...` 로 override 가능

### 주요 도메인별 API

- **엑셀 업로드 (`UploadApi`)**
  - 모바일: `uploadExcel(filePath, fileName)` → `BaseApiClient.postMultipart('/upload/excel', ...)`
  - 웹: `uploadExcelBytes(fileBytes, fileName)` → `BaseApiClient.postMultipartBytes(...)`
  - 업로드 후 서버가 parquet/데이터 저장

- **거래내역 / 통계 (`TransactionApi`, `StatsApi`)**
  - 거래 리스트: `GET /transactions` (페이지네이션)
  - 월별 통계: `GET /stats/monthly`

- **과소비 분석 / 규칙 (`AnalysisApi`)**
  - 패턴 분석: `GET /analysis/overspending`
  - 규칙 목록: `GET /analysis/rules`
  - 규칙 생성: `POST /analysis/rules`
  - 규칙 수정: `PUT /analysis/rules/{id}`
  - 규칙 삭제: `DELETE /analysis/rules/{id}`

---

## 4. 플랫폼별 처리 (웹 / 모바일)

- **파일 선택**
  - `ExcelUploadButton`에서 `file_picker` 사용
  - `kIsWeb` 기준 분기:
    - 웹: `UploadApi.uploadExcelBytes(file.bytes!, file.name)`
    - 모바일: `UploadApi.uploadExcel(file.path!, file.name)`

- **파일 검증**
  - 모바일: `upload_file_validator.dart` (dart:io 사용)
  - 웹: `upload_file_validator_stub.dart` (호출되면 에러 던지는 stub)
  - 조건부 import로 자동 분기

- **Firebase + FCM**
  - `main.dart`에서 `!kIsWeb` 일 때만 `Firebase.initializeApp()` + `FCMService().init()`

- **외부 앱 실행**
  - `AppLauncherService.openBankSalad()`
    - 우선 `market://details?id=...` 시도
    - 안 되면 Play Store 웹 URL로 fallback

---

## 5. 빌드 & 배포 메모

- **로컬 개발**
  - 백엔드: `uvicorn app.main:app --reload --port 8000`
  - 프론트: `flutter run` (에뮬레이터 or 웹)

- **Android 배포 (참고)**
  - `flutter build apk --release`
  - `flutter build appbundle --release` (Play Store 용)