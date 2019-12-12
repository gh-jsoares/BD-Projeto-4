DROP TABLE IF EXISTS local_publico CASCADE;
DROP TABLE IF EXISTS item CASCADE;
DROP TABLE IF EXISTS anomalia CASCADE;
DROP TABLE IF EXISTS anomalia_traducao CASCADE;
DROP TABLE IF EXISTS duplicado CASCADE;
DROP TABLE IF EXISTS utilizador CASCADE;
DROP TABLE IF EXISTS utilizador_qualificado CASCADE;
DROP TABLE IF EXISTS utilizador_regular CASCADE;
DROP TABLE IF EXISTS incidencia CASCADE;
DROP TABLE IF EXISTS proposta_de_correcao CASCADE;
DROP TABLE IF EXISTS correcao CASCADE;
DROP TABLE IF EXISTS d_utilizador CASCADE;
DROP TABLE IF EXISTS d_tempo CASCADE;
DROP TABLE IF EXISTS d_local CASCADE;
DROP TABLE IF EXISTS d_lingua CASCADE;
DROP TABLE IF EXISTS f_anomalia CASCADE;

CREATE TABLE local_publico (
	latitude DECIMAL (9, 6) NOT NULL,
	longitude DECIMAL(9, 6) NOT NULL,
	nome VARCHAR(255) NOT NULL,
	CONSTRAINT pk_local_publico PRIMARY KEY (latitude, longitude)
);

CREATE TABLE item (
	id SERIAL PRIMARY KEY,
	descricao VARCHAR(255) NOT NULL,
	localizacao VARCHAR(255) NOT NULL,
	latitude DECIMAL (9, 6) NOT NULL,
	longitude DECIMAL(9, 6) NOT NULL,
	FOREIGN KEY (latitude, longitude) REFERENCES local_publico(latitude, longitude) ON DELETE CASCADE
);

CREATE TABLE anomalia (
	id SERIAL PRIMARY KEY,
	zona BOX NOT NULL,
	imagem VARCHAR(255) NOT NULL,
	lingua VARCHAR(255) NOT NULL,
	ts TIMESTAMP NOT NULL DEFAULT NOW(),
	descricao VARCHAR(255) NOT NULL,
	tem_anomalia_redacao BOOLEAN NOT NULL
);

CREATE TABLE anomalia_traducao (
	id INT NOT NULL PRIMARY KEY,
	zona2 VARCHAR(255) NOT NULL,
	lingua2 VARCHAR(255) NOT NULL,
	FOREIGN KEY (id) REFERENCES anomalia(id) ON DELETE CASCADE
);

CREATE TABLE duplicado (
	item1 INT NOT NULL,
	item2 INT NOT NULL,
	FOREIGN KEY (item1) REFERENCES item(id) ON DELETE CASCADE,
	FOREIGN KEY (item2) REFERENCES item(id) ON DELETE CASCADE,
	CONSTRAINT pk_duplicado PRIMARY KEY (item1, item2),
	CHECK (item1 < item2)
);

CREATE TABLE utilizador (
	email VARCHAR(255) NOT NULL PRIMARY KEY,
	password VARCHAR(255) NOT NULL
);

CREATE TABLE utilizador_qualificado (
	email VARCHAR(255) NOT NULL PRIMARY KEY,
	FOREIGN KEY (email) REFERENCES utilizador(email) ON DELETE CASCADE
);

CREATE TABLE utilizador_regular (
	email VARCHAR(255) NOT NULL PRIMARY KEY,
	FOREIGN KEY (email) REFERENCES utilizador(email) ON DELETE CASCADE
);

CREATE TABLE incidencia (
	anomalia_id INT NOT NULL PRIMARY KEY,
	item_id INT NOT NULL,
	email VARCHAR(255) NOT NULL,
	FOREIGN KEY (anomalia_id) REFERENCES anomalia(id) ON DELETE CASCADE,
	FOREIGN KEY (item_id) REFERENCES item(id) ON DELETE CASCADE,
	FOREIGN KEY (email) REFERENCES utilizador(email) ON DELETE CASCADE
);

CREATE TABLE proposta_de_correcao (
	email VARCHAR(255) NOT NULL,
	nro SERIAL,
	data_hora TIMESTAMP NOT NULL DEFAULT NOW(),
	texto TEXT,
	FOREIGN KEY (email) REFERENCES utilizador_qualificado(email) ON DELETE CASCADE,
	CONSTRAINT pk_proposta_de_correcao PRIMARY KEY (email, nro)
);

CREATE TABLE correcao (
	email VARCHAR(255) NOT NULL,
	nro INT NOT NULL,
	anomalia_id INT NOT NULL,
	FOREIGN KEY (nro, email) REFERENCES proposta_de_correcao(nro, email) ON DELETE CASCADE,
	FOREIGN KEY (anomalia_id) REFERENCES incidencia(anomalia_id) ON DELETE CASCADE,
	CONSTRAINT pk_correcao PRIMARY KEY (email, nro, anomalia_id)
);

CREATE TABLE d_utilizador (
	id_utilizador SERIAL PRIMARY KEY,
	email VARCHAR(255) NOT NULL,
	tipo VARCHAR(11) NOT NULL
);

CREATE TABLE d_tempo (
	id_tempo SERIAL PRIMARY KEY,
	dia INT NOT NULL,
	dia_da_semana INT NOT NULL,
	semana INT NOT NULL,
	mes INT NOT NULL,
	trimestre INT NOT NULL,
	ano INT NOT NULL
);

CREATE TABLE d_local (
	id_local SERIAL PRIMARY KEY,
	latitude DECIMAL (9, 6) NOT NULL,
	longitude DECIMAL(9, 6) NOT NULL,
	nome VARCHAR(255) NOT NULL
);

CREATE TABLE d_lingua (
	id_lingua SERIAL PRIMARY KEY,
	lingua VARCHAR(255) NOT NULL
);

CREATE TABLE f_anomalia (
	id_utilizador INT NOT NULL,
	id_tempo INT NOT NULL,
	id_local INT NOT NULL,
	id_lingua INT NOT NULL,
	tipo_anomalia VARCHAR(11) NOT NULL,
	com_proposta BOOLEAN NOT NULL,
	FOREIGN KEY (id_utilizador) REFERENCES d_utilizador(id_utilizador) ON DELETE CASCADE,
	FOREIGN KEY (id_tempo) REFERENCES d_tempo(id_tempo) ON DELETE CASCADE,
	FOREIGN KEY (id_local) REFERENCES d_local(id_local) ON DELETE CASCADE,
	FOREIGN KEY (id_lingua) REFERENCES d_lingua(id_lingua) ON DELETE CASCADE,
	CONSTRAINT pk_f_anomalia PRIMARY KEY (id_utilizador, id_tempo, id_local, id_lingua)
);


--- RI-1

CREATE OR REPLACE FUNCTION check_anomalia() RETURNS TRIGGER AS $$
BEGIN
	IF (box (NEW.zona2) && (box ((SELECT zona FROM anomalia WHERE id = NEW.id)))) THEN
		RAISE EXCEPTION 'A zona da anomalia_tradução não se pode sobrepor à zona da anomalia correspondente';

	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER anomalia_traducao_sobrepor BEFORE INSERT OR UPDATE ON anomalia_traducao
FOR EACH ROW EXECUTE PROCEDURE check_anomalia();

--- RI-4

CREATE OR REPLACE FUNCTION check_email_utilizador() RETURNS TRIGGER AS $$
BEGIN

  IF (NEW.email) NOT IN (SELECT email FROM utilizador_regular UNION SELECT email FROM utilizador_qualificado WHERE email = NEW.email) THEN
  	RAISE EXCEPTION 'email de utilizador tem de figurar em utilizador_qualificado ou utilizador_regular';

  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER email_utilizador AFTER INSERT OR UPDATE ON utilizador
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE PROCEDURE check_email_utilizador();

--- RI-5

CREATE OR REPLACE FUNCTION check_utilizador_regular() RETURNS TRIGGER AS $$
BEGIN

  IF (NEW.email) IN (SELECT email FROM utilizador_regular WHERE email = NEW.email) THEN
  	RAISE EXCEPTION 'email não pode figurar em utilizador_regular';

  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER email_utilizador_qualificado BEFORE INSERT OR UPDATE ON utilizador_qualificado
FOR EACH ROW EXECUTE PROCEDURE check_utilizador_regular();

--- RI-6

CREATE OR REPLACE FUNCTION check_utilizador_qualificado() RETURNS TRIGGER AS $$
BEGIN

  IF (NEW.email) IN (SELECT email FROM utilizador_qualificado WHERE email = NEW.email) THEN
  	RAISE EXCEPTION 'email não pode figurar em utilizador_qualificado';

  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER email_utilizador_regular BEFORE INSERT OR UPDATE ON utilizador_regular
FOR EACH ROW EXECUTE PROCEDURE check_utilizador_qualificado();
