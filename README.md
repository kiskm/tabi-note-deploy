# tabi-note

旅行の記録・管理を行う Web アプリケーション。

## Tech Stack

| カテゴリ | 技術 |
|---------|------|
| Frontend | Next.js / Tailwind CSS |
| Backend | NestJS / TypeORM |
| Database | PostgreSQL |
| Infrastructure | AWS (EC2 / VPC / S3) / Terraform |
| Container | Docker / Docker Compose |
| CI/CD | GitHub Actions |

## アーキテクチャ

```mermaid
graph TB
    subgraph GitHub
        A[tabi-note-api] -->|push/PR| B[CI: Build]
        C[tabi-note-front] -->|push/PR| D[CI: Build]
        E[tabi-note-deploy] -->|.tf変更| F[plan / apply]
        E -->|docker-compose.yml変更| G[Deploy]
    end

    subgraph AWS
        subgraph VPC
            subgraph EC2["EC2 (t2.micro / Amazon Linux 2023)"]
                H[Docker Compose]
                H --> I[front :3000]
                H --> J[api :8000]
                H --> K[db :5432]
            end
        end
        L[S3: tfstate]
    end

    F -->|terraform apply| EC2
    G -->|SSH + git pull + docker compose| H
    F -.->|state| L
```

## インフラ構成

Terraform で以下のリソースを管理。

- **VPC** — 192.168.0.0/20
- **EC2** — t2.micro、パブリックサブネット (ca-central-1)
- **Security Group** — フロント(3000)・API(8000) を公開、SSH はデプロイ時のみ動的許可
- **S3** — Terraform state 管理

## CI/CD パイプライン

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant GH as GitHub Actions
    participant AWS as AWS

    Dev->>GH: PR作成 (.tf変更)
    GH->>AWS: terraform plan
    GH->>Dev: PRにplanをコメント

    Dev->>GH: mainにマージ
    GH->>AWS: terraform apply

    Dev->>GH: docker-compose.yml変更
    GH->>AWS: EC2のIPを動的取得
    GH->>AWS: SGにランナーIPを一時追加
    GH->>AWS: SSH → git pull → docker compose
    GH->>AWS: ヘルスチェック
    GH->>AWS: SGからランナーIPを削除
```

## リポジトリ構成

| リポジトリ | 内容 |
|-----------|------|
| tabi-note-deploy | Terraform / Docker Compose / GitHub Actions |
| tabi-note-api | NestJS API |
| tabi-note-front | Next.js フロントエンド |
