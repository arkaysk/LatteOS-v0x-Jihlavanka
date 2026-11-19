ALTER TABLE "channel_categories" ADD COLUMN "folder" text;--> statement-breakpoint
ALTER TABLE "artifacts" DROP COLUMN "category_id";