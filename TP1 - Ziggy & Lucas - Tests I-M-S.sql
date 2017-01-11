/*
  FICHIER DE TESTS.
*/

/*
  Table stock : sélection
*/
Select * from Stock;    --Requête standard
Select * from Stock natural join produits;    -- Jointure

Select count(*), Pays from Stock
GROUP BY PAYS;        --Test de regroupement

/*
  Table Stock : LMD
*/
insert into stock values (1 , 'Mexique', 5 , 1 ,0);     -- Fonctionne : Le tuple est inséré dans la table Stock_AM du site américain
commit;

delete from stock where ref_produit=1 and PAYS='Mexique';     -- Fonctionne également : le tuple inséré est supprimé dans le fragment correspondant
commit;

insert into stock values (2,'Portugal',54,1,0);     --Fonctionne : le tuple est inséré dans la table stockES du site d'Europe du Sud
insert into stock values (2, 'Portugal', 44, 12, 1);    --Erreur : contrainte d'intégrité (PK) non respectée
insert into stock values (195, 'INEX', 4,4, 5); -- Erreur : contrainte d'intégrité liée à Produits (FK distante assurée par trigger) non respectée => le tuple est destiné à la table stockOI
insert into stock values (195, 'Portugal', 4,4, 5);  -- Erreur : contrainte d'intégrité (FK locale) non respectée

insert into Stock values (3, 'Suede', 12, 2, 7);        
update Stock set unites_commandees = 24 where pays='Suede' and ref_produit=3;   --Idem : le fragment concerné est ici StockEN
delete from stock where pays='Suede' and ref_produit=3;

update stock set unites_stock =null where pays='Portugal' and ref_produit=2;  --  Fonctionne : la commande UPDATE concerne ici le fragment stockES
UPDATE Stock set unites_stock=4 where pays='INEX' and ref_produit=null;     --Fonctionne, mais MAJ de 0 ligne
update stock set INDISPONIBLE=1 where pays='Allemagne' and ref_produit=1;   --Fonctionne : la commande UPDATE concerne ici le fragment stockEN

delete from stock where pays='Portugal' and ref_produit=2;      --Fonctionne : la comande DELETE concerne le fragment stockES
delete from stock where pays= 'Honduras' and ref_produit=1;     -- Fonctionne, mais suppression de 0 ligne

rollback;         --  Rollback jusqu'avant l'insertion du produit 2 au Portugal

/*
  Table Clients : sélection
*/
Select * from Clients;    --Requête standard

Select * from Clients 
where code_client NOT IN
(Select code_client from Clients natural join Commandes);     -- Jointure : clients n'ayant fait aucune commande

Select * from Clients c1, Commandes c2, details_commandes dc, Produits p, Stock s
WHERE c1.CODE_CLIENT = c2.code_client
and c2.no_commande = dc.no_commande
and dc.ref_produit = p.ref_produit and p.ref_produit = s.ref_produit
and c1.pays = s.pays;             -- Jointure : Clients ayant commandé un produit en stock dans leur pays

/*
  Table Clients : LMD
*/

insert into clients values ('54321', 'Testcomp', '1, Boulevard des palmiers', 'Panama', '88855', 'Panama', '010203405', '0607080900');    --Fonctionne : insère le tuple dans le fragment américain.
insert into clients values ('54322', 'Testcomp2', '1, rue de la Fayette', 'Dijon', '21000', 'France', '010203405', '0607080900');    --Fonctionne : insère le tuple dans le fragment local européen du sud
insert into clients values (null,  'Testcomp', '1, Boulevard des palmiers', 'Panama', '88855', 'Panama', '010203405', '0607080900');  --Erreur:  violation de clé primaire 
insert into commandes values ('66666', '54321', 3, SYSDATE, sysdate, 12);   ---Fonctionne : la commande se trouve sur le fragment américain
delete from clients where code_client='54321';    -- Erreur : violation de contrainte d'intégrité assurée par un trigger distant sur la base américaine.
delete from commandes where no_commande='66666';  -- Fonctionne, commande non référencée dans une table secondaire

delete from clients where code_client = '54321';      --Fonctionne : supprime le client du fragment américain
update clients set code_client = null;        --Erreur : contrainte d'intégrité de clé primaire
update clients set code_client = 'TESTX' where code_client = 'OTTIK';       --Ne fonctionne pas : le client allemand OTTIK est enregistré dans une commande (FK du fragment ClientsEN)
delete from clients where code_client=null;   --Fonctionne mais ne supprime aucun client (code_client est une PK)

rollback;       --Annulation

/*
  Table Commandes : sélection
*/             
select * from commandes;    --Sélection standard

select no_commande, code_client, (date_Envoi - date_Commande) as dureeExpedition from commandes
where date_Envoi is not null and date_Commande is not null;     --Sélection avec where (durée en jours du processus d'expédition des commandes par commande)

select  as dureeExpedition from commandes
where date_Envoi is not null and date_Commande is not null;     --Sélection avec where (durée du processus d'expédition des commandes par commande)

select sum(port) from commandes;        -- USage d'une fonction d'agrégation sur un regroupement
ALTER TABLE commandesES ADD CONSTRAINT pk_commandesES PRIMARY KEY (NO_COMMANDE);

/*
    Table Commandes : LMD
*/

select * from clients;
insert into commandes values (123457,'VINET',2,SYSDATE,SYSDATE,25); --Fonctionne : commande destinée au fragment d'europe du Sud.
insert into commandes values (123457,'BLONP',2,SYSDATE,SYSDATE,25); -- Ne fonctionne pas : violation de contrainte unique.

update commandes set code_client='OTTIK' where NO_COMMANDE='123457'; -- Fonctionne : OTTIK est allemand.
update commandes set code_client='ZIGGY' where NO_COMMANDE='123457'; -- Ne fonctionne pas : ZIGGY est inconnu (peu importe le site)

delete from commandes where NO_COMMANDE='123457';   --OK : la commande est liée à un client allemand (OTTIK)
delete from commandes where NO_COMMANDE='5555';         -- Comme en centralisé, si aucun tuple n'est repéré, aucune erreur n'intervient.          
insert into commandes values (159842, 'ANTON', 1, sysdate, sysdate, 2); --- OK : le client Anton est Mexicain.
insert into details_commandes values(159842, 1, 2,3,4);   --OK : insertion dans la table detailsCommandes
select * from details_commandes where no_commande=159842; 

delete from commandes where NO_COMMANDE=159842;    --KO:  contrainte de clé étrangère distante depuis DetailsCommande
delete from details_commandes where no_commande=159842;
delete from commandes where NO_COMMANDE=159842;  -- OK : La commande est supprimée
rollback;

/*
  Table DetailsCommande : Sélection
*/
select * from details_commandes;
select * from details_commandes where quantite >= 100;

/*
  Table DetailsCommandes : LMD
*/
select * from clients natural join commandes;
insert into details_Commandes values (10286, 3, 3, 4, 5);  --OK : insertion dans le fragment details_commandesEN (Europe du Nord). LA commande provient d'un client allemand
delete from commandes where no_commande=10286;          --KO : trigger de violation de contrainte FK appelé à distance
delete from produits where ref_produit=3;       -- KO : trigger de violation de contrainte local portant sur la table primaire Produits
insert into details_commandes values (444,2,54,1,1.2); --KO : le client de la commande 444 est inconnu car la commande 444 n'existe pas
insert into details_Commandes values (10286, 888, 3, 4, 5);  --KO : le produit spécifié est inexistant
update details_commandes set quantite=15 where NO_COMMANDE=10286 and ref_produit=3;   --OK : La MAJ est appliquée sur le fragment local
update details_commandes set quantite=20 where NO_COMMANDE=10522 and ref_produit=40;   --OK : La MAJ est appliquée sur un fragment distane (Europe du Nord)
update details_commandes set no_commande = 122 where no_commande=123457; --OK : la commande n'existe pas mais la mise à jour n'affecte donc aucune ligne
delete from details_commandes where no_commande = 122;      -- OK mais ne supprime rien car la commande 122 est absente de la table

rollback;

