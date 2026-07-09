from sqlalchemy.orm import DeclarativeBase
from sqlalchemy import MetaData

# Associate metadata with the 'scout' schema.
# This ensures all defined models are automatically created in the 'scout' schema.
metadata_obj = MetaData(schema="scout")

class Base(DeclarativeBase):
    metadata = metadata_obj
