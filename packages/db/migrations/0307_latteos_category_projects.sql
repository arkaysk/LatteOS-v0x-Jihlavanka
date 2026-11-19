ALTER TABLE "channel_categories" DROP CONSTRAINT "channel_categories_orgId_name_unique";--> statement-breakpoint
ALTER TABLE "channels" DROP CONSTRAINT "channels_parent_id_channels_id_fk";
--> statement-breakpoint
ALTER TABLE "channel_categories" ADD COLUMN "parent_id" uuid;--> statement-breakpoint
ALTER TABLE "channel_categories" ADD COLUMN "project_type" "channel_project_type";--> statement-breakpoint
ALTER TABLE "channel_categories" ADD COLUMN "project_state" "channel_project_state" DEFAULT 'active' NOT NULL;--> statement-breakpoint
ALTER TABLE "channel_categories" ADD COLUMN "instructions" text DEFAULT '' NOT NULL;--> statement-breakpoint
ALTER TABLE "artifacts" ADD COLUMN "category_id" uuid;--> statement-breakpoint
ALTER TABLE "channel_categories" ADD CONSTRAINT "channel_categories_parent_id_channel_categories_id_fk" FOREIGN KEY ("parent_id") REFERENCES "public"."channel_categories"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "channels" DROP COLUMN "parent_id";--> statement-breakpoint
ALTER TABLE "channels" DROP COLUMN "project_state";--> statement-breakpoint
ALTER TABLE "channels" DROP COLUMN "project_type";--> statement-breakpoint
ALTER TABLE "channels" DROP COLUMN "instructions";--> statement-breakpoint
ALTER TABLE "channel_categories" ADD CONSTRAINT "channel_categories_orgId_parentId_name_unique" UNIQUE NULLS NOT DISTINCT("org_id","parent_id","name");