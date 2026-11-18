CREATE TYPE "public"."channel_project_state" AS ENUM('active', 'paused', 'done');--> statement-breakpoint
CREATE TYPE "public"."channel_project_type" AS ENUM('code', 'drawing', 'book', '3d', 'music', 'comic', 'other');--> statement-breakpoint
ALTER TABLE "channels" ADD COLUMN "parent_id" uuid;--> statement-breakpoint
ALTER TABLE "channels" ADD COLUMN "project_state" "channel_project_state" DEFAULT 'active' NOT NULL;--> statement-breakpoint
ALTER TABLE "channels" ADD COLUMN "project_type" "channel_project_type";--> statement-breakpoint
ALTER TABLE "channels" ADD CONSTRAINT "channels_parent_id_channels_id_fk" FOREIGN KEY ("parent_id") REFERENCES "public"."channels"("id") ON DELETE set null ON UPDATE no action;