FROM ubuntu:20.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PG_VERSION=15
ENV PATH="/usr/local/pgsql/bin:$PATH"
ENV PGDATA="/usr/local/pgsql/data"

# Install required packages
RUN apt-get update && apt-get install -y \
    build-essential \
    libreadline-dev \
    zlib1g-dev \
    flex \
    bison \
    libxml2-dev \
    libxslt-dev \
    libssl-dev \
    locales \
    wget \
    git && \
    apt-get clean

# Set up locale to prevent prompts
RUN locale-gen en_US.UTF-8 && update-locale LANG=en_US.UTF-8

# Create the postgres user and group
RUN groupadd -r postgres && useradd -r -g postgres postgres

# Clone PostgreSQL and pg_query_state sources
WORKDIR /build
RUN git clone --depth 1 --branch REL_${PG_VERSION}_STABLE https://github.com/postgres/postgres.git && \
    git clone https://github.com/postgrespro/pg_query_state.git

# Apply pg_query_state patches to PostgreSQL source
WORKDIR /build/postgres
RUN for patch in /build/pg_query_state/patches/*${PG_VERSION}*.patch; do patch -p1 < $patch; done

# Copy pg_query_state into the PostgreSQL contrib directory
RUN cp -r /build/pg_query_state /build/postgres/contrib/pg_query_state

# Compile PostgreSQL, including pg_query_state
RUN ./configure --prefix=/usr/local/pgsql && make -j$(nproc) && make install

# Install pg_query_state extension
WORKDIR /build/postgres/contrib/pg_query_state
RUN make -j$(nproc) && make install

# Clean up build dependencies and intermediate files
RUN apt-get remove -y build-essential git && \
    apt-get autoremove -y && \
    rm -rf /build && \
    apt-get clean

# Initialize the PostgreSQL database
RUN mkdir -p $PGDATA && chown -R postgres:postgres /usr/local/pgsql

# Fetch and add the official PostgreSQL entrypoint
RUN wget -O /usr/local/bin/docker-entrypoint.sh https://raw.githubusercontent.com/docker-library/postgres/master/docker-entrypoint.sh && \
    chmod +x /usr/local/bin/docker-entrypoint.sh

# Switch to postgres user
USER postgres

# Set the entrypoint and default command
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["postgres"]
