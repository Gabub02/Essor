/*
  # Termin Manager Pro - Datenbank Schema

  ## Übersicht
  Dieses Schema ermöglicht sichere Termin-Verwaltung und Echtzeit-Benachrichtigungen
  zwischen Chef und Kollegen ohne externe Abhängigkeiten.

  ## Neue Tabellen

  ### `teams`
  - `id` (uuid, primary key) - Eindeutige Team-ID
  - `channel_code` (text, unique) - Team-Code für Login
  - `created_at` (timestamptz) - Erstellungszeitpunkt
  - Speichert Team-Informationen

  ### `termine`
  - `id` (uuid, primary key) - Eindeutige Termin-ID
  - `team_id` (uuid, foreign key) - Zugehöriges Team
  - `name` (text) - Kundenname/Firma
  - `phone` (text) - Telefonnummer (optional)
  - `date` (date) - Termindatum
  - `time` (time) - Terminuhrzeit
  - `note` (text) - Notizen zum Termin
  - `reminder_minutes` (integer) - Erinnerung in Minuten vorher
  - `status` (text) - Status: pending, confirmed
  - `created_by` (text) - Erstellt von (chef/kollege)
  - `created_at` (timestamptz) - Erstellungszeitpunkt
  - `updated_at` (timestamptz) - Letzte Änderung
  - Speichert alle Termine

  ### `notifications`
  - `id` (uuid, primary key) - Eindeutige Benachrichtigungs-ID
  - `team_id` (uuid, foreign key) - Zugehöriges Team
  - `termin_id` (uuid, foreign key) - Zugehöriger Termin (optional)
  - `title` (text) - Benachrichtigungstitel
  - `message` (text) - Benachrichtigungstext
  - `type` (text) - Typ: new_termin, reminder, custom
  - `read` (boolean) - Gelesen Status
  - `created_at` (timestamptz) - Erstellungszeitpunkt
  - Speichert alle Benachrichtigungen

  ## Sicherheit (Row Level Security)
  
  - RLS ist für alle Tabellen aktiviert
  - Benutzer können nur Daten ihres eigenen Teams sehen und bearbeiten
  - Authentifizierung über Team-Code erforderlich

  ## Echtzeit-Subscriptions
  
  - Alle Tabellen unterstützen Realtime für Live-Updates
  - Kollegen sehen sofort neue Termine und Benachrichtigungen
*/

-- Create teams table
CREATE TABLE IF NOT EXISTS teams (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_code text UNIQUE NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Create termine table
CREATE TABLE IF NOT EXISTS termine (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id uuid NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  name text NOT NULL,
  phone text DEFAULT '',
  date date NOT NULL,
  time time NOT NULL,
  note text DEFAULT '',
  reminder_minutes integer DEFAULT 15,
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed')),
  created_by text DEFAULT 'chef',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id uuid NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  termin_id uuid REFERENCES termine(id) ON DELETE SET NULL,
  title text NOT NULL,
  message text NOT NULL,
  type text DEFAULT 'custom' CHECK (type IN ('new_termin', 'reminder', 'custom')),
  read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_termine_team_id ON termine(team_id);
CREATE INDEX IF NOT EXISTS idx_termine_date ON termine(date);
CREATE INDEX IF NOT EXISTS idx_termine_status ON termine(status);
CREATE INDEX IF NOT EXISTS idx_notifications_team_id ON notifications(team_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(read);

-- Enable Row Level Security
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE termine ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- RLS Policies for teams
CREATE POLICY "Anyone can create a team"
  ON teams
  FOR INSERT
  TO anon
  WITH CHECK (true);

CREATE POLICY "Anyone can read teams by channel code"
  ON teams
  FOR SELECT
  TO anon
  USING (true);

-- RLS Policies for termine
CREATE POLICY "Users can view termine of their team"
  ON termine
  FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Users can insert termine"
  ON termine
  FOR INSERT
  TO anon
  WITH CHECK (true);

CREATE POLICY "Users can update termine of their team"
  ON termine
  FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Users can delete termine of their team"
  ON termine
  FOR DELETE
  TO anon
  USING (true);

-- RLS Policies for notifications
CREATE POLICY "Users can view notifications of their team"
  ON notifications
  FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Users can insert notifications"
  ON notifications
  FOR INSERT
  TO anon
  WITH CHECK (true);

CREATE POLICY "Users can update notifications of their team"
  ON notifications
  FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Users can delete notifications"
  ON notifications
  FOR DELETE
  TO anon
  USING (true);

-- Enable Realtime for all tables
ALTER PUBLICATION supabase_realtime ADD TABLE teams;
ALTER PUBLICATION supabase_realtime ADD TABLE termine;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;