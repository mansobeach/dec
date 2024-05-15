from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# TypeError: SQLite DateTime type only accepts Python datetime and date objects as input

# SQLALCHEMY_DATABASE_URL = "sqlite:///./sqlite3_app.db"

SQLALCHEMY_DATABASE_URL = 'postgresql://e2edc:e2edc#5432@localhost/postgres'

engine = create_engine(SQLALCHEMY_DATABASE_URL)

'''
sqlite3 specific argument check_same_thread

engine = create_engine(
    # By default SQLite will only allow one thread to communicate with it, assuming that each thread would handle an independent request
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
'''


SessionLocal = sessionmaker(autocommit = False, autoflush = False, bind = engine)

# inherit from this class to create each of the database models or classes (the ORM models)
Base = declarative_base()


