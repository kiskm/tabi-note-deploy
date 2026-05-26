# API設計書

## 概要

| 項目         | 内容                   |
| ------------ | ---------------------- |
| ベースURL    | `http://<EC2-IP>:8000` |
| フォーマット | JSON                   |
| 認証         | JWT認証                |

## エンドポイント一覧

### Auth

| メソッド | パス           | 説明                          | ステータスコード |
| -------- | -------------- | ----------------------------- | ---------------- |
| POST     | `/auth/signup` | ユーザー登録                  | 201              |
| POST     | `/auth/login`  | ログイン（JWTトークンを返す） | 200              |

#### POST /auth/signup

**リクエストボディ**

```json
{
  "userName": "taro",
  "password": "password123"
}
```

| フィールド | 型     | 必須 | バリデーション |
| ---------- | ------ | ---- | -------------- |
| userName   | string | YES  | MaxLength 100  |
| password   | string | YES  | MinLength 8    |

**レスポンス**

```json
{
  "id": 1,
  "userName": "taro"
}
```

---

#### POST /auth/login

**リクエストボディ**

```json
{
  "userName": "taro",
  "password": "password123"
}
```

| フィールド | 型     | 必須 | バリデーション |
| ---------- | ------ | ---- | -------------- |
| userName   | string | YES  | -              |
| password   | string | YES  | -              |

**レスポンス**

```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

---

## 認証が必要なエンドポイント

Trips / Spots / Expenses の全エンドポイントはログイン済みユーザーのみアクセス可。リクエスト時に以下のヘッダーを付与すること。

```
Authorization: Bearer <accessToken>
```

---

### Trips

| メソッド | パス         | 説明         | ステータスコード |
| -------- | ------------ | ------------ | ---------------- |
| GET      | `/trips`     | 旅行一覧取得 | 200              |
| GET      | `/trips/:id` | 旅行詳細取得 | 200              |
| POST     | `/trips`     | 旅行作成     | 201              |
| PATCH    | `/trips/:id` | 旅行更新     | 200              |
| DELETE   | `/trips/:id` | 旅行削除     | 204              |

#### GET /trips

**レスポンス**

```json
[
  {
    "id": 1,
    "title": "京都旅行",
    "startDate": "2025-03-01",
    "endDate": "2025-03-03",
    "area": "京都",
    "status": "done",
    "budget": 50000,
    "spots": []
  }
]
```

#### GET /trips/:id

**レスポンス**

```json
{
  "id": 1,
  "title": "京都旅行",
  "startDate": "2025-03-01",
  "endDate": "2025-03-03",
  "area": "京都",
  "status": "done",
  "budget": 50000,
  "spots": [
    {
      "id": 1,
      "name": "金閣寺",
      "category": "観光",
      "memo": null,
      "lat": 35.0394,
      "lng": 135.7292,
      "imageUrl": null,
      "checked": true,
      "tripId": 1
    }
  ],
  "expenses": [
    {
      "id": 1,
      "category": "transport",
      "amount": 15000,
      "memo": "新幹線",
      "tripId": 1
    }
  ]
}
```

#### POST /trips

**リクエストボディ**

```json
{
  "title": "京都旅行",
  "startDate": "2025-03-01",
  "endDate": "2025-03-03",
  "area": "京都",
  "status": "want",
  "budget": 50000
}
```

| フィールド | 型               | 必須 | バリデーション |
| ---------- | ---------------- | ---- | -------------- |
| title      | string           | YES  | MaxLength 100  |
| startDate  | string           | NO   | DateString形式 |
| endDate    | string           | NO   | DateString形式 |
| area       | string           | NO   | MaxLength 100  |
| status     | 'want' \| 'done' | NO   | enum           |
| budget     | number           | NO   | Min 0          |

---

### Spots

| メソッド | パス                   | 説明                 | ステータスコード |
| -------- | ---------------------- | -------------------- | ---------------- |
| POST     | `/trips/:tripId/spots` | スポット作成         | 201              |
| PATCH    | `/spots/:id`           | スポット更新         | 200              |
| PATCH    | `/spots/:id/check`     | チェック状態切り替え | 200              |
| DELETE   | `/spots/:id`           | スポット削除         | 204              |

#### POST /trips/:tripId/spots

**リクエストボディ**

```json
{
  "name": "金閣寺",
  "category": "観光",
  "memo": "朝一で行く",
  "lat": 35.0394,
  "lng": 135.7292,
  "imageUrl": null
}
```

| フィールド | 型     | 必須 | バリデーション |
| ---------- | ------ | ---- | -------------- |
| name       | string | YES  | MaxLength 100  |
| category   | string | NO   | MaxLength 50   |
| memo       | string | NO   | MaxLength 500  |
| lat        | number | NO   | -              |
| lng        | number | NO   | -              |
| imageUrl   | string | NO   | -              |

---

### Expenses

| メソッド | パス                      | 説明     | ステータスコード |
| -------- | ------------------------- | -------- | ---------------- |
| POST     | `/trips/:tripId/expenses` | 費用作成 | 201              |
| PATCH    | `/expenses/:id`           | 費用更新 | 200              |
| DELETE   | `/expenses/:id`           | 費用削除 | 204              |

#### POST /trips/:tripId/expenses

**リクエストボディ**

```json
{
  "category": "transport",
  "amount": 15000,
  "memo": "新幹線"
}
```

| フィールド | 型                                          | 必須 | バリデーション       |
| ---------- | ------------------------------------------- | ---- | -------------------- |
| category   | 'transport' \| 'hotel' \| 'food' \| 'other' | YES  | enum                 |
| amount     | number                                      | YES  | Min 0, Max 9,999,999 |
| memo       | string                                      | NO   | MaxLength 500        |

---

### ヘルスチェック

| メソッド | パス | レスポンス       |
| -------- | ---- | ---------------- |
| GET      | `/`  | `"Hello World!"` |
