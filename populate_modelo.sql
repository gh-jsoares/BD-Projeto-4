--- Populate d_utilizador

CREATE OR REPLACE FUNCTION populate_d_utilizador() RETURNS VOID AS $$
DECLARE tipo VARCHAR(11);
DECLARE email_u VARCHAR(255);

BEGIN
	FOR email_u IN (SELECT DISTINCT email FROM incidencia)
	LOOP
		IF email_u IN (SELECT email FROM utilizador_qualificado) THEN
			tipo = 'qualificado';
		ELSIF email_u IN (SELECT email FROM utilizador_regular) THEN
			tipo = 'regular';
		END IF;

		INSERT INTO d_utilizador VALUES (DEFAULT, email_u, tipo);
	END LOOP;
END;
$$ LANGUAGE plpgsql;

SELECT populate_d_utilizador();

--- Populate d_tempo

CREATE OR REPLACE FUNCTION populate_d_tempo() RETURNS VOID AS $$
DECLARE ts_a TIMESTAMP;

BEGIN
	FOR ts_a IN (SELECT ts FROM anomalia)
	LOOP
		INSERT INTO d_tempo VALUES (DEFAULT, date_part('day', ts_a), date_part('dow', ts_a), date_part('week', ts_a), date_part('month', ts_a), date_part('quarter', ts_a), date_part('year', ts_a));
	END LOOP;
END;
$$ LANGUAGE plpgsql;

SELECT populate_d_tempo();

--- Populate d_local

CREATE OR REPLACE FUNCTION populate_d_local() RETURNS VOID AS $$
DECLARE lat_l DECIMAL (9, 6);
DECLARE long_l DECIMAL (9, 6);
DECLARE nome_l VARCHAR(255);

BEGIN
	FOR lat_l, long_l, nome_l IN (SELECT latitude, longitude, localizacao FROM item)
	LOOP
		INSERT INTO d_local VALUES (DEFAULT, lat_l, long_l, nome_l);
	END LOOP;
END;
$$ LANGUAGE plpgsql;

SELECT populate_d_local();

--- Populate d_lingua

CREATE OR REPLACE FUNCTION populate_d_lingua() RETURNS VOID AS $$
DECLARE lingua_a VARCHAR(255);

BEGIN
	FOR lingua_a IN (SELECT lingua FROM anomalia)
	LOOP
		INSERT INTO d_lingua VALUES (DEFAULT, lingua_a);
	END LOOP;
END;
$$ LANGUAGE plpgsql;

SELECT populate_d_lingua();

-- aux f_anomalia

CREATE OR REPLACE FUNCTION search_id_utilizador(e VARCHAR(255)) RETURNS INT AS $$
	DECLARE id INT;

	BEGIN
		SELECT id_utilizador INTO id
		FROM d_utilizador
		WHERE email = e;

	RETURN id;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION search_id_tempo(ts TIMESTAMP) RETURNS INT AS $$
	DECLARE id INT;

	BEGIN
		SELECT id_tempo INTO id
		FROM d_tempo
		WHERE dia = date_part('day', ts) AND
			dia_da_semana = date_part('dow', ts) AND
			semana = date_part('week', ts) AND
			mes = date_part('month', ts) AND
			trimestre = date_part('quarter', ts) AND
			ano = date_part('year', ts);

	RETURN id;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION search_id_local(lat DECIMAL (9, 6), long DECIMAL (9, 6)) RETURNS INT AS $$
	DECLARE id INT;

	BEGIN
		SELECT id_local INTO id
		FROM d_local
		WHERE latitude = lat AND
			longitude = long;

	RETURN id;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION search_id_lingua(l VARCHAR(255)) RETURNS INT AS $$
	DECLARE id INT;

	BEGIN
		SELECT id_lingua INTO id
		FROM d_lingua
		WHERE lingua = l;

	RETURN id;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION search_proposta(id INT) RETURNS BOOLEAN AS $$
	BEGIN
		IF id NOT IN (SELECT anomalia_id FROM correcao) THEN
			RETURN 'false';
		ELSE
			RETURN 'true';
		END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION search_redacao(b BOOLEAN) RETURNS VARCHAR AS $$
	BEGIN
		IF (b = 'true') THEN
			RETURN 'redacao';
		ELSE
			RETURN 'traducao';
		END IF;
END;
$$ LANGUAGE plpgsql;

--- Populate f_anomalia

CREATE OR REPLACE FUNCTION populate_f_anomalia() RETURNS VOID AS $$
DECLARE id_u INT;
DECLARE id_t INT;
DECLARE id_lo INT;
DECLARE id_li INT;
DECLARE tipo_anomalia VARCHAR(8);
DECLARE a_redacao BOOLEAN;
DECLARE a_proposta BOOLEAN;

DECLARE a_email VARCHAR(255);
DECLARE a_ts TIMESTAMP;
DECLARE a_lat DECIMAL (9, 6);
DECLARE a_long DECIMAL (9, 6);
DECLARE a_ling VARCHAR(255);
DECLARE a_id INT;

BEGIN
	FOR a_email, a_ts, a_lat, a_long, a_ling, a_redacao, a_id IN (SELECT email, ts, latitude, longitude, lingua, tem_anomalia_redacao, anomalia_id FROM anomalia JOIN incidencia ON anomalia_id = anomalia.id JOIN item ON item_id = item.id)
	LOOP
		SELECT search_id_utilizador(a_email) INTO id_u;
		SELECT search_id_tempo(a_ts) INTO id_t;
		SELECT search_id_local(a_lat, a_long) INTO id_lo;
		SELECT search_id_lingua(a_ling) INTO id_li;
		SELECT search_redacao(a_redacao) INTO tipo_anomalia;
		SELECT search_proposta(a_id) INTO a_proposta;

		INSERT INTO f_anomalia VALUES (id_u, id_t, id_lo, id_li, tipo_anomalia, a_proposta);

	END LOOP;

END;
$$ LANGUAGE plpgsql;

SELECT populate_f_anomalia();
