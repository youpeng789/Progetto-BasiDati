create table Carta(
Nome varchar(30),
Costo int not null,
Sconto int not null,
check(Costo>0 AND (Sconto>0 AND Sconto<100)),
primary key(Nome)
); 

create table Assicurazione(
Nome varchar(30),
Costo int not null,
Durata int not null,
check(Costo>0 AND Durata>0 ),
primary key(Nome)
); 



create table Sede(
Codice int,
Citta varchar(30) not null,
Tipo_Indirizzo varchar(20) not null,
Nome_Indirizzo varchar(50) not null,
Numero_Indirizzo int not null,
CAP int not null, 
check(CAP>0 and Numero_Indirizzo>0 and Codice>100),
check(Tipo_Indirizzo = 'Via' or 
	  Tipo_Indirizzo = 'Viale' or 
	  Tipo_Indirizzo = 'Vico' or
	  Tipo_Indirizzo = 'Piazza' or
	  Tipo_Indirizzo = 'Piazzale' or
          Tipo_Indirizzo = 'Corso'),
primary key(Codice)
);



create table Azienda(
Nome varchar(50),
Capitale int not null,	
primary key (Nome),
check(Capitale>0)
);



create table Negozio(
Nome varchar(50) unique,
Sede int,
Valutazione varchar(20) not null,
primary key (Nome,Sede),
foreign key (Sede) references Sede(Codice),
check(Valutazione='Molto scarso' or Valutazione='Scarso' or Valutazione='Medio' or Valutazione='Buono' or Valutazione='Molto buono' )
);


create table Magazzino(
Nome varchar(30) unique,
Negozio varchar(50) unique,
Sede int not null,
Capienza int not null,
primary key (Nome,Negozio),
foreign key (Negozio) references Negozio(Nome),
foreign key (Sede) references Sede (Codice),
check(Capienza>0)
);




create table Cliente(
CF int,
Nome varchar(30) not null,
Cognome varchar(30) not null,
Eta int not null,
Carta varchar(30) not null,
primary key (CF),
foreign key (Carta) references Carta(Nome),
check (CF>10000 and Eta>0)
);


create table Lavoratore(
CF int,
Nome varchar(30) not null,
Cognome varchar(30) not null,
Eta int not null,
Negozio varchar(50) not null,
Stipendio int not null,
Data_Inizio date not null,
Sconto_Lavoratore int not null,
Ruolo varchar(30) not null,
primary key (CF),
foreign key (Negozio) references Negozio(Nome),
check (CF>10000 and Eta>0 and Stipendio>0 and Sconto_Lavoratore>0 and Sconto_Lavoratore<100),
check(extract(year from Data_Inizio)-(2024-Eta)>=18),
check (Ruolo='Dipendente' or Ruolo='Responsabile')
);


create table Prodotto(
Nome varchar(50),
Costo int not null , 
Anno_Di_Uscita int not null,
Azienda varchar(50) not null,
Generazione int,
Eta_Minima int,
Piattaforma varchar(20),
Numero_DLC int,
Tipo_Prodotto varchar(10),
primary key (Nome),
foreign key (Azienda) references Azienda(Nome),
check(Anno_Di_Uscita<2025 and Anno_Di_Uscita>1980 
	  and Costo>0
	  and Generazione>0
	  and Eta_Minima>=3 and Eta_Minima<=18
	  and Numero_DLC>=0),
check(Tipo_Prodotto='Console' or Tipo_Prodotto='Gioco')
);



create table Disponibilita_Immediata(
Prodotto varchar(50),
Negozio varchar(50),
Numero int not null,
primary key(Prodotto,Negozio),
foreign key(Prodotto) references Prodotto(Nome),
foreign key(Negozio) references Negozio(Nome),
check(Numero>0)
);



create table CRM(
Cliente int,
Negozio varchar(50),
Numero_Acquisti int not null,
primary key(Cliente,Negozio),
foreign key(Cliente) references Cliente(CF),
foreign key (Negozio) references Negozio(Nome),
check(Numero_Acquisti>0)
);



create table Deposito(
Magazzino varchar(30),
Prodotto varchar(50),
Numero int not null,
primary key(Magazzino,Prodotto),
foreign key(Magazzino) references Magazzino(Nome),
foreign key(Prodotto) references Prodotto(Nome),
check(Numero>0)
);




create table Scontrino(
Codice int,
Negozio varchar(50) not null,
Cliente int not null,
Prodotto varchar(50) not null,
Assicurazione varchar(30),
Prezzo_Totale real not null,
Data date not null,
Data_Fine_Assicurazione date,
primary key(Codice),
foreign key (Negozio) references Negozio(Nome),
foreign key (Cliente) references Cliente(CF),
foreign key (Prodotto) references Prodotto(Nome),
foreign key (Assicurazione) references Assicurazione(Nome),
check(Codice>1000 and Prezzo_Totale>0),
check(Data_Fine_Assicurazione>=Data)
);





CREATE INDEX Idx_Deposito ON Deposito (Magazzino,Prodotto);

create function check_stessa_persona() returns trigger as 
$Body$

declare 
nome varchar(30);
cognome varchar(30);
eta int;
numero_persona int;
begin

   select count(Lavoratore.CF)
   into numero_persona
   from Lavoratore
   where Lavoratore.CF=new.CF;
   
   select Lavoratore.Nome, Lavoratore.Cognome,Lavoratore.Eta
   into nome,cognome,eta
   from Lavoratore 
   where Lavoratore.CF=new.CF;
   
if((numero_persona=1 and  
   nome=new.nome and
   cognome=new.cognome and
   eta=new.eta) or numero_persona=0)
   then return new;
   else RAISE EXCEPTION $$Sono presenti due persone con lo stesso CF %, 
	                    ma sono due persone diverse$$, new.CF;
   end if;
	  
end;
	  
$Body$
LANGUAGE PLPGSQL;

CREATE TRIGGER check_stessa_persona
AFTER INSERT OR UPDATE
ON Cliente
FOR EACH ROW 
EXECUTE PROCEDURE check_stessa_persona();






create function check_responsabile_singolo() returns trigger as 
$Body$

declare 
numero_responsabili int;

begin

   select count(Ruolo)
   into numero_responsabili
   from Lavoratore 
   where Lavoratore.Negozio=new.Negozio and Ruolo='Responsabile';
   
   if(numero_responsabili<=1)
   then return new;
   else raise exception $$Sono/Sarebbero presenti due o più responsabili 
                        nello stesso negozio %$$,new.Negozio;
   end if;
	  
end;
	  
$Body$
LANGUAGE PLPGSQL;

CREATE TRIGGER check_singolo_responsabile
AFTER INSERT OR UPDATE
ON Lavoratore
FOR EACH ROW 
EXECUTE PROCEDURE check_responsabile_singolo();




create function check_numero_prodotti_magazzino() returns trigger as 
$Body$

declare 
prodotti int;
max_numero_prodotti int;
begin

   select sum(numero)
   into prodotti
   from Deposito
   where Magazzino=new.Magazzino;
   
   select capienza
   into max_numero_prodotti
   from Magazzino
   where Nome=new.Magazzino;
   
   if(prodotti<=max_numero_prodotti)
   then return new;
   else raise exception $$Sono/Sarebbero presenti più prodotti (%) di quelli 
                        che il magazzino % può contenere.$$
                        ,prodotti,new.Magazzino;
   end if;
	  
end;
	  
$Body$
LANGUAGE PLPGSQL;

CREATE TRIGGER check_prodotti_magazzino
AFTER INSERT OR UPDATE
ON Deposito
FOR EACH ROW 
EXECUTE PROCEDURE check_numero_prodotti_magazzino();



create function check_acquisti_cliente() returns trigger as 
$Body$

declare 
cf_cliente int;
begin

   select cliente
   into cf_cliente
   from crm
   where cliente=new.cliente and negozio=new.negozio;
   
   if(cf_cliente>0)
   then update crm
        set numero_acquisti=numero_acquisti+1
	where cliente=new.cliente and negozio=new.negozio;
   else insert into crm values (new.cliente,new.negozio,1);
   end if;
   return new;
end;
	  
$Body$
LANGUAGE PLPGSQL;

CREATE TRIGGER check_numero_acquisti_cliente
AFTER INSERT
ON Scontrino
FOR EACH ROW 
EXECUTE PROCEDURE check_acquisti_cliente();




create function check_acquisti_clienti_delete() returns trigger as
$Body$
declare
delete_acquisti int;
begin

select numero_acquisti
into delete_acquisti
from CRM
where cliente=old.cliente and negozio=old.negozio;

if(delete_acquisti>1) then
update CRM
set numero_acquisti=numero_acquisti-1
where cliente=old.cliente and negozio=old.negozio;
else
delete from crm where cliente=old.cliente and negozio=old.negozio;
end if;
return new;
end;

$Body$
LANGUAGE PLPGSQL;

CREATE TRIGGER check_numero_acquisti_cliente_delete
AFTER DELETE
ON Scontrino
FOR EACH ROW 
EXECUTE PROCEDURE check_acquisti_clienti_delete();




create function check_data_fine_assicurazione() returns trigger as 
$Body$
declare

data_fine1 date;
data_fine2 date;
data_fine3 date;

begin

data_fine1=new.data+ interval '4 month';
data_fine2=new.data+ interval '12 month';
data_fine3=new.data+ interval '24 month'; 

        if(new.assicurazione='Bronze') 
		then
		update Scontrino
		set data_fine_assicurazione=data_fine1
		where codice=new.codice;
		return new;
		end if;
		
		if(new.assicurazione='Silver') 
		then
		update Scontrino
		set data_fine_assicurazione=data_fine2
		where codice=new.codice;
		return new;
		end if;
		
		if(new.assicurazione='Gold') 
		then
		update Scontrino
		set data_fine_assicurazione=data_fine3
		where codice=new.codice;
		return new;
		else
   
   update Scontrino
		set data_fine_assicurazione=new.data
		where codice=new.codice;
		return new;
	end if;
   
   end;

$Body$
LANGUAGE PLPGSQL;


CREATE TRIGGER check_data_fine_assicurazione
AFTER INSERT
ON Scontrino
FOR EACH ROW 
EXECUTE PROCEDURE check_data_fine_assicurazione();




create function check_prezzo_totale_scontrino() returns trigger as 
$Body$

declare 

cliente_lavoratore int;
sconto_cliente int;
valore_sconto_lavoratore int;
prezzo_prodotto int;
prezzo_assicurazione int;

begin

   select count(CF)
   into cliente_lavoratore
   from Lavoratore 
   where Lavoratore.CF=new.cliente;
   
   select costo
   into prezzo_prodotto
   from Prodotto
   where nome=new.prodotto;
   
   if(new.assicurazione='Gold' or new.assicurazione='Silver' or new.assicurazione='Bronze'  )      then
        select costo
        into prezzo_assicurazione
		from Assicurazione
		where nome=new.assicurazione;
		else prezzo_assicurazione=0;
   end if;
   
   select sconto 
        into sconto_cliente
        from Carta 
		where nome=(select carta 
                    from cliente
		            where CF=new.cliente);
   
   if(cliente_lavoratore=1)
   then select sconto_lavoratore
		into valore_sconto_lavoratore
		from Lavoratore
		where CF=new.cliente;
   else   valore_sconto_lavoratore=0;
   end if;
   
   if(sconto_cliente>valore_sconto_lavoratore)
   then
   update Scontrino
   set prezzo_totale=prezzo_prodotto+prezzo_assicurazione
                          -((prezzo_prodotto*sconto_cliente)/100)
   where codice=new.codice;
   else 
   update Scontrino
   set prezzo_totale=prezzo_prodotto+prezzo_assicurazione
                     -((prezzo_prodotto*valore_sconto_lavoratore)/100);
   end if;
   
   return new;
   
end;
	  
$Body$
LANGUAGE PLPGSQL;

CREATE TRIGGER check_prezzo_totale_scontrino
AFTER INSERT
ON Scontrino
FOR EACH ROW 
EXECUTE PROCEDURE check_prezzo_totale_scontrino();




create function check_anno_di_uscita() returns trigger as
$Body$
declare
anno_gioco int;
anno_vendita int;
begin

anno_vendita=extract(year from new.data);

select anno_di_uscita
into anno_gioco
from Prodotto
where nome=new.prodotto;

if(anno_gioco<=anno_vendita) then return new;
else raise exception $$Impossibile aver acquistato il prodotto in data % se questo è uscito nel %$$,new.data,anno_gioco; 
end if;
end;

$Body$
LANGUAGE PLPGSQL;

CREATE TRIGGER check_anno_di_uscita
AFTER INSERT OR UPDATE
ON Scontrino
FOR EACH ROW 
EXECUTE PROCEDURE check_anno_di_uscita();



insert into Carta values 
('Standard',5,10),
('Premium',10,20),
('Deluxe',20,50);



insert into Assicurazione values 
('Bronze',2,4),
('Silver',5,12),
('Gold',8,24);



insert into Sede values
(101,'Roma','Vico','dei Palazzi',4,42134),
(102,'Milano','Via','Luzzi',12,12345),
(103,'Padova','Corso','Stazione',1,35132),
(104,'Venezia','Piazzale','San Lorenzo',34,56789),
(105,'Cremona','Piazza','Degna',26,97269),
(106,'Castrovillari','Via','Romanica',33,27861),
(107,'Napoli','Via','M.Destri',82,74528),
(108,'Firenze','Vico','Bruno',1,15673);



insert into Azienda values
('AZ_1',35),
('AZ_2',12),
('AZ_3',8),
('AZ_4',120),
('AZ_5',200),
('AZ_6',50),
('AZ_7',700),
('AZ_8',33),
('AZ_9',500),
('AZ_10',175);


insert into Negozio values
('GS_1','101','Molto buono'),
('GS_2','102','Buono'),
('GS_3','101','Molto scarso'),
('GS_4','104','Scarso'),
('GS_5','103','Medio');


insert into Magazzino values
('MG_1','GS_1',101,50),
('MG_2','GS_4',106,20),
('MG_3','GS_5',103,150),
('MG_4','GS_3',108,100),
('MG_5','GS_2',105,75);

insert into Cliente values
(10001,'Gabriele','Magnelli',22,'Standard'),
(10002,'Youpeng','Liu',24,'Deluxe'),
(10003,'Alessia','Marangon',31,'Premium'),
(10008,'Rex','T',45,'Standard'),
(10011,'Lica','Romanescu',52,'Deluxe'),
(10016,'Ubert','Abart',18,'Standard'),
(10100,'Bianca','Scura',30,'Premium'),
(10020,'Roberto','Pierfavino',19,'Premium'),
(10012,'Mara','Torner',22,'Standard'),
(11111,'Mina','Toti',25,'Deluxe'),
(10209,'Romano','Serro',46,'Premium'),
(10022,'Antonio','Sosso',61,'Deluxe'),
(10045,'Saverio','Difra',27,'Premium'),
(10134,'Maria','Nanno',36,'Premium'),
(12222,'Antonio','Silva',20,'Standard'),
(10210,'Rio','Papu',33,'Standard'),
(10044,'Riccardo','Stante',45,'Deluxe');

insert into Lavoratore values
(10001,'Gabriele','Magnelli',22,'GS_1',1000,'2023-01-10',25,'Dipendente'),
(10002,'Youpeng','Liu',24,'GS_2',3000,'2023-05-20',30,'Responsabile'),
(10003,'Alessia','Marangon',31,'GS_1',1600,'2021-09-05',25,'Dipendente'),
(10005,'Giovanni','Rotondo',19,'GS_1',800,'2024-05-20',10,'Dipendente'),
(10006,'Sebastiana','Derin',33,'GS_1',4000,'2019-03-20',45,'Responsabile'),
(10007,'Maxime','Sartori',18,'GS_1',1000,'2024-01-01',12,'Dipendente'),
(10011,'Lica','Romanescu',52,'GS_3',5000,'1990-05-21',65,'Responsabile'),
(10012,'Mara','Torner',22,'GS_3',1200,'2022-12-31',18,'Dipendente'),
(10013,'Piero','Diavolo',36,'GS_3',1000,'2009-07-09',29,'Dipendente'),
(10020,'Roberto','Pierfavino',19,'GS_4',2350,'2023-11-17',10,'Dipendente'),
(10021,'Anna','Acca',44,'GS_4',760,'2001-06-11',65,'Dipendente'),
(10022,'Antonio','Sosso',61,'GS_4',950,'1985-12-07',65,'Dipendente'),
(10030,'Alex','Irato',39,'GS_5',1870,'2006-09-06',65,'Dipendente'),
(10033,'Manuel','Rocci',39,'GS_4',4500,'2004-02-21',65,'Responsabile'),
(10209,'Romano','Serro',46,'GS_5',3500,'2017-04-13',65,'Responsabile'),
(11111,'Mina','Toti',25,'GS_5',500,'2019-08-27',65,'Dipendente');


insert into Prodotto values
('Baldurs Gate 3',60,2023,'AZ_1',null,18,'PC',0,'Gioco'),
('Divinity Original Sin',30,2017,'AZ_2',null,18,'PC',2,'Gioco'),
('DeadFire',5,2010,'AZ_1',null,12,'PS4',0,'Gioco'),
('PS1',100,1994,'AZ_3',1,null,null,null,'Console'),
('COD BO6',80,2024,'AZ_4',null,18,'PC',1,'Gioco'),
('Total War Rome 2',25,2013,'AZ_5',null,12,'PC',12,'Gioco'),
('UFC 5',65,2023,'AZ_6',null,18,'PS5',0,'Gioco'),
('PS5',450,2020,'AZ_9',5,null,null,0,'Console'),
('FIFA 25',80,2024,'AZ_7',null,3,'XBOX ONE',0,'Gioco'),
('XBOX ONE',375,2020,'AZ_8',5,null,null,0,'Console'),
('God of War V',80,2022,'AZ_6',null,12,'PS5',0,'Gioco'),
('Godzilla',5,1999,'AZ_7',null,18,'PS1',0,'Gioco'),
('Civilization 7',65,2024,'AZ_8',null,7,'XBOX ONE',2,'Gioco'),
('Batman',40,2017,'AZ_7',null,16,'PC',3,'Gioco'),
('Dragon Ball Z',52,2024,'AZ_9',null,12,'PC',2,'Gioco'),
('Max Payne',3,2001,'AZ_9',null,18,'PS2',0,'Gioco'),
('PS2',100,1999,'AZ_10',2,null,null,0,'Console');


insert into disponibilita_immediata values
('Baldurs Gate 3','GS_1',10),
('PS1','GS_1',4),
('PS5','GS_1',10),
('Divinity Original Sin','GS_1',10),
('UFC 5','GS_1',10),
('DeadFire','GS_1',10),
('FIFA 25','GS_1',10),
('Civilization 7','GS_1',10),
('Total War Rome 2','GS_1',6),
('Dragon Ball Z','GS_1',16),
('Godzilla','GS_2',18),
('Batman','GS_2',4),
('XBOX ONE','GS_2',8),
('PS1','GS_2',3),
('Divinity Original Sin','GS_2',12),
('FIFA 25','GS_2',2),
('COD BO6','GS_2',21),
('Civilization 7','GS_2',9),
('God of War V','GS_2',8),
('UFC 5','GS_2',10),
('Civilization 7','GS_3',14),
('Baldurs Gate 3','GS_3',4),
('XBOX ONE','GS_3',7),
('DeadFire','GS_3',5),
('God of War V','GS_3',4),
('Godzilla','GS_3',8),
('Max Payne','GS_3',10),
('PS5','GS_3',17),
('Dragon Ball Z','GS_3',9),
('Total War Rome 2','GS_3',10),
('Dragon Ball Z','GS_4',12),
('Baldurs Gate 3','GS_4',6),
('PS2','GS_4',8),
('Batman','GS_4',11),
('PS1','GS_4',15),
('PS5','GS_4',18),
('Max Payne','GS_4',8),
('Divinity Original Sin','GS_4',6),
('COD BO6','GS_4',1),
('Civilization 7','GS_4',11),
('Total War Rome 2','GS_5',9),
('Baldurs Gate 3','GS_5',7),
('Dragon Ball Z','GS_5',5),
('FIFA 25','GS_5',3),
('Godzilla','GS_5',15),
('PS1','GS_5',5),
('XBOX ONE','GS_5',25),
('PS2','GS_5',1),
('UFC 5','GS_5',19),
('Batman','GS_5',22);


insert into deposito values
('MG_1','DeadFire',10),
('MG_1','Divinity Original Sin',20),
('MG_1','Baldurs Gate 3',15),
('MG_1','PS1',5),
('MG_2','UFC 5',5),
('MG_2','COD BO6',5),
('MG_2','God of War V',3),
('MG_2','FIFA 25',7),
('MG_3','XBOX ONE',20),
('MG_3','PS5',30),
('MG_3','PS2',10),
('MG_3','Dragon Ball Z',10),
('MG_3','Batman',15),
('MG_3','Total War Rome 2',15),
('MG_4','Civilization 7',25),
('MG_4','COD BO6',35),
('MG_4','Divinity Original Sin',5),
('MG_4','FIFA 25',7),
('MG_4','XBOX ONE',5),
('MG_4','Batman',10),
('MG_5','PS2',1),
('MG_5','Godzilla',7),
('MG_5','Max Payne',7),
('MG_5','DeadFire',5),
('MG_5','PS1',10),
('MG_5','PS5',20);


insert into scontrino values
(1001,'GS_1',10001,'Baldurs Gate 3','Bronze',1,'2024-01-01',null),
(1002,'GS_1',10001,'Dragon Ball Z','Gold',1,'2024-05-03',null),
(1024,'GS_1',10003,'Divinity Original Sin',null,1,'2022-05-09',null),
(1004,'GS_2',12222,'Batman','Gold',1,'2024-07-06',null),
(1005,'GS_1',10003,'Godzilla','Bronze',1,'2021-09-18',null),
(1006,'GS_3',10002,'Batman','Gold',1,'2020-10-11',null),
(1007,'GS_4',10008,'FIFA 25','Gold',1,'2024-01-13',null),
(1008,'GS_2',10001,'God of War V','Bronze',1,'2022-05-25',null),
(1009,'GS_3',10011,'PS2','Bronze',1,'2018-09-30',null),
(1010,'GS_5',10001,'Max Payne','Bronze',1,'2019-05-27',null),
(1025,'GS_1',10003,'Divinity Original Sin','Gold',1,'2017-04-22',null),
(1012,'GS_4',12222,'Total War Rome 2','Silver',1,'2015-02-01',null),
(1013,'GS_2',10002,'Total War Rome 2','Gold',1,'2016-08-10',null),
(1014,'GS_5',10016,'God of War V','Bronze',1,'2024-06-19',null),
(1015,'GS_4',12222,'XBOX ONE','Silver',1,'2024-10-09',null),
(1016,'GS_4',10002,'UFC 5',null,1,'2023-11-08',null),
(1017,'GS_1',10001,'PS5',null,1,'2022-12-06',null),
(1018,'GS_3',10011,'PS5','Gold',1,'2022-01-19',null),
(1019,'GS_3',10011,'Baldurs Gate 3','Silver',1,'2023-08-12',null),
(1020,'GS_4',12222,'DeadFire',null,1,'2011-11-15',null),
(1021,'GS_5',10016,'PS2','Silver',1,'2019-09-14',null),
(1011,'GS_1',10003,'DeadFire','Bronze',1,'2014-10-31',null),
(1022,'GS_1',10001,'PS1',null,1,'2001-04-22',null),
(1023,'GS_2',10002,'PS5','Silver',1,'2022-07-21',null),
(1041,'GS_4',10002,'Max Payne','Gold',1,'2021-04-05',null),
(1026,'GS_3',10003,'Batman','Bronze',1,'2018-01-09',null),
(1027,'GS_3',10008,'Godzilla','Bronze',1,'2012-07-23',null),
(1028,'GS_2',10011,'Godzilla','Silver',1,'2008-11-22',null),
(1029,'GS_1',10100,'God of War V','Bronze',1,'2022-08-08',null),
(1030,'GS_1',10020,'FIFA 25','Gold',1,'2024-12-30',null),
(1031,'GS_5',10012,'UFC 5','Silver',1,'2023-06-27',null),
(1032,'GS_2',11111,'Godzilla',null,1,'2009-10-01',null),
(1033,'GS_1',10022,'DeadFire',null,1,'2011-09-14',null),
(1034,'GS_4',10209,'COD BO6','Bronze',1,'2024-05-18',null),
(1035,'GS_4',10045,'UFC 5','Gold',1,'2023-02-21',null),
(1036,'GS_3',10134,'COD BO6',null,1,'2024-07-24',null),
(1037,'GS_2',12222,'PS1','Silver',1,'2001-06-12',null),
(1038,'GS_3',10210,'Batman','Silver',1,'2019-10-25',null),
(1040,'GS_5',10001,'Dragon Ball Z','Gold',1,'2024-06-09',null),
(1039,'GS_5',10044,'XBOX ONE',null,1,'2023-05-16',null);