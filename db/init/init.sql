DO $$
BEGIN
    RAISE NOTICE 'Starting database initialization...';
END $$;

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

DO $$
BEGIN
    RAISE NOTICE 'UUID extension enabled.';
END $$;

-- Users table to store player information
CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    account_balance DECIMAL(15, 2) DEFAULT 0.00,
    created_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        last_login TIMESTAMP
    WITH
        TIME ZONE,
        is_active BOOLEAN DEFAULT true,
        verification_status VARCHAR(20) DEFAULT 'unverified'
);

-- Tables table to store different poker tables
CREATE TABLE tables (
    table_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    name VARCHAR(100) NOT NULL,
    game_type VARCHAR(50) NOT NULL, -- Texas Hold'em, Omaha, etc.
    stakes_type VARCHAR(20) NOT NULL, -- cash, tournament
    min_buy_in DECIMAL(15, 2) NOT NULL,
    max_buy_in DECIMAL(15, 2) NOT NULL,
    small_blind DECIMAL(15, 2) NOT NULL,
    big_blind DECIMAL(15, 2) NOT NULL,
    max_players INTEGER NOT NULL DEFAULT 9,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Active sessions at tables
CREATE TABLE table_sessions (
    session_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    table_id UUID REFERENCES tables (table_id),
    user_id UUID REFERENCES users (user_id),
    seat_number INTEGER NOT NULL,
    stack_amount DECIMAL(15, 2) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    joined_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        UNIQUE (
            table_id,
            seat_number,
            is_active
        )
);

-- Hands played at tables
CREATE TABLE hands (
    hand_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    table_id UUID REFERENCES tables (table_id),
    start_time TIMESTAMP
    WITH
        TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        end_time TIMESTAMP
    WITH
        TIME ZONE,
        pot_size DECIMAL(15, 2) DEFAULT 0.00,
        community_cards VARCHAR(15), -- Format: "2h3d4sAcKs"
        status VARCHAR(20) DEFAULT 'in_progress'
);

-- Player actions in hands
CREATE TABLE hand_actions (
    action_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    hand_id UUID REFERENCES hands (hand_id),
    user_id UUID REFERENCES users (user_id),
    action_type VARCHAR(20) NOT NULL, -- fold, call, raise, check
    amount DECIMAL(15, 2),
    action_time TIMESTAMP
    WITH
        TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        round VARCHAR(10) NOT NULL -- preflop, flop, turn, river
);

-- Player cards in hands
CREATE TABLE player_cards (
    hand_id UUID REFERENCES hands (hand_id),
    user_id UUID REFERENCES users (user_id),
    hole_cards VARCHAR(4) NOT NULL, -- Format: "AhKd"
    PRIMARY KEY (hand_id, user_id)
);

-- Tournaments
CREATE TABLE tournaments (
    tournament_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    name VARCHAR(100) NOT NULL,
    buy_in DECIMAL(15, 2) NOT NULL,
    starting_chips INTEGER NOT NULL,
    max_players INTEGER NOT NULL,
    status VARCHAR(20) DEFAULT 'registering',
    start_time TIMESTAMP
    WITH
        TIME ZONE,
        end_time TIMESTAMP
    WITH
        TIME ZONE,
        prize_pool DECIMAL(15, 2) DEFAULT 0.00,
        created_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tournament registrations
CREATE TABLE tournament_registrations (
    tournament_id UUID REFERENCES tournaments (tournament_id),
    user_id UUID REFERENCES users (user_id),
    registration_time TIMESTAMP
    WITH
        TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        status VARCHAR(20) DEFAULT 'active', -- active, eliminated, finished
        final_position INTEGER,
        prize_amount DECIMAL(15, 2),
        PRIMARY KEY (tournament_id, user_id)
);

-- Transaction history
CREATE TABLE transactions (
    transaction_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    user_id UUID REFERENCES users (user_id),
    type VARCHAR(50) NOT NULL, -- deposit, withdrawal, buy-in, cash-out, tournament entry
    amount DECIMAL(15, 2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    reference_id UUID, -- Could reference hand_id or tournament_id
    created_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Chat messages
CREATE TABLE chat_messages (
    message_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    table_id UUID REFERENCES tables (table_id),
    user_id UUID REFERENCES users (user_id),
    message TEXT NOT NULL,
    created_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for better query performance
CREATE INDEX idx_hands_table_id ON hands (table_id);

CREATE INDEX idx_hand_actions_hand_id ON hand_actions (hand_id);

CREATE INDEX idx_transactions_user_id ON transactions (user_id);

CREATE INDEX idx_table_sessions_table_id ON table_sessions (table_id);

CREATE INDEX idx_tournament_registrations_tournament_id ON tournament_registrations (tournament_id);

-- Add basic constraints
ALTER TABLE table_sessions
ADD CONSTRAINT valid_seat_number CHECK (
    seat_number >= 1
    AND seat_number <= 9
);

ALTER TABLE transactions
ADD CONSTRAINT positive_amount CHECK (amount > 0);

ALTER TABLE tables
ADD CONSTRAINT valid_blinds CHECK (small_blind < big_blind);

ALTER TABLE tables
ADD CONSTRAINT valid_buy_in CHECK (min_buy_in <= max_buy_in);