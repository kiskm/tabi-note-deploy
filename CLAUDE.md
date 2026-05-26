# tabi-note-deploy — Claude Context

## プロジェクト概要

旅行メモアプリ「tabi-note」のインフラ・デプロイ管理リポジトリ。

## リポジトリ構成

3つの独立したリポジトリで構成される。

| リポジトリ | 役割 |
|-----------|------|
| tabi-note-deploy（本リポジトリ） | Terraform / Docker Compose / GitHub Actions |
| tabi-note-api | NestJS API サーバー |
| tabi-note-front | Next.js フロントエンド |

## アプリケーション構成

| レイヤー | 技術 |
|---------|------|
| フロントエンド | Next.js 16 + Tailwind CSS |
| バックエンド | NestJS 11 + TypeORM |
| データベース | PostgreSQL 15 |
| コンテナ | Docker Compose |

**ドメインモデル:** Trip（旅行）/ Spot（スポット）/ Expense（費用）

## インフラ構成（AWS / Terraform）

| リソース | 内容 |
|---------|------|
| EC2 | t2.micro (Amazon Linux 2023) |
| VPC | 192.168.0.0/20、パブリックサブネット (ca-central-1a) |
| Security Group | HTTP 3000/8000、SSH は実行ユーザー IP のみ |
| S3 | Terraform state 管理 (tabi-note-tfstate) |

EC2 の user_data でリポジトリをクローンし、Docker Compose でビルド・起動する。  
ビルドはメモリ節約のため api → front の順に逐次実行。

## GitHub Actions ワークフロー

| ファイル | トリガー | 内容 |
|---------|---------|------|
| plan.yml | PR (.tf/.tfvars 変更時) | fmt / validate / plan → PR にコメント |
| apply.yml | main push (.tf/.tfvars 変更時) | terraform apply |
| deploy.yml | main push (docker-compose.yml 変更時) / 手動 | EC2 に SSH して git pull + docker compose 再起動 |

**deploy.yml の仕組み:**
1. AWS CLI で EC2 のパブリック IP をタグ名から動的取得
2. ランナーの IP をセキュリティグループに一時追加
3. SSH でデプロイ実行
4. ヘルスチェック（`docker compose ps | grep "Up"`）
5. セキュリティグループからランナーの IP を削除（`if: always()`）

## Terraform 変数

機密情報は GitHub Variables / Secrets で管理。`.tfvars` は `.gitignore` 対象。

| 変数 | 管理場所 |
|-----|---------|
| TF_VAR_project | GitHub Variables |
| TF_VAR_environment | GitHub Variables |
| AWS_ACCESS_KEY_ID | GitHub Secrets |
| AWS_SECRET_ACCESS_KEY | GitHub Secrets |
| EC2_SSH_KEY | GitHub Secrets |

## ローカル開発

```bash
# インフラ操作（AWS profile: terraform）
terraform plan
terraform apply

# アプリ起動
docker compose up --build
```

## ファイル構成

```
.
├── main.tf          # Terraform 設定・プロバイダー・S3 バックエンド
├── network.tf       # VPC / サブネット / ルートテーブル / IGW
├── security-group.tf # セキュリティグループ
├── appserver.tf     # EC2 インスタンス / キーペア
├── data.tf          # AMI / My IP データソース
├── locals.tf        # ローカル変数（自分の IP）
├── docker-compose.yml
└── .github/workflows/
    ├── plan.yml
    ├── apply.yml
    └── deploy.yml
```
