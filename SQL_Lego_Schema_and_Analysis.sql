-- PART 1 CREATE TABLES AND FORM RELATIONSHIPS

-- create a schema in our database
create schema Carla_Lego;

-- create all tables
create table til_portfolio_projects.carla_lego.COLORS (
ID number,
NAME varchar(50),
RGB varchar(6),
IS_TRANS varchar(1)
);

create table til_portfolio_projects.carla_lego.INVENTORIES (
ID number,
VERSION number,
SET_NUM varchar(20)
);

create table til_portfolio_projects.carla_lego.INVENTORY_PARTS (
INVENTORY_ID number,
PART_NUM varchar(15),
COLOR_ID number,
QUANTITY number,
IS_SPARE varchar(1)
);

create table til_portfolio_projects.carla_lego.INVENTORY_SETS (
INVENTORY_ID number,
SET_NUM varchar(20),
QUANTITY number 
);

create table til_portfolio_projects.carla_lego.PARTS (
PART_NUM varchar(15),
NAME varchar(225),
PART_CAT_ID number
);

create table til_portfolio_projects.carla_lego.PART_CATEGORIES (
ID number,
NAME varchar(50)
);

create table til_portfolio_projects.carla_lego.SETS (
SET_NUM varchar(20),
NAME varchar(100),
YEAR number,
THEME_ID number,
NUM_PARTS number
);

create table til_portfolio_projects.carla_lego.THEMES (
ID number,
NAME varchar(50),
PARENT_ID varchar(10)

);

-- insert data into the tables

insert into til_portfolio_projects.carla_lego.COLORS
select *
from til_portfolio_projects.staging_schema.COLORS;

insert into til_portfolio_projects.carla_lego.INVENTORIES
select *
from til_portfolio_projects.staging_schema.INVENTORIES;

insert into til_portfolio_projects.carla_lego.INVENTORY_PARTS
select *
from til_portfolio_projects.staging_schema.INVENTORY_PARTS;

insert into til_portfolio_projects.carla_lego.INVENTORY_SETS
select *
from til_portfolio_projects.staging_schema.INVENTORY_SETS;

insert into til_portfolio_projects.carla_lego.PARTS
select *
from til_portfolio_projects.staging_schema.PARTS;

insert into til_portfolio_projects.carla_lego.PART_CATEGORIES
select *
from til_portfolio_projects.staging_schema.PART_CATEGORIES;

insert into til_portfolio_projects.carla_lego.SETS
select *
from til_portfolio_projects.staging_schema.SETS;

insert into til_portfolio_projects.carla_lego.THEMES
select *
from til_portfolio_projects.staging_schema.THEMES;

-- test
select * 
from themes;

-- setting primary keys

ALTER TABLE INVENTORY_SETS ADD PRIMARY KEY (INVENTORY_ID);
ALTER TABLE INVENTORY_PARTS ADD PRIMARY KEY (INVENTORY_ID);
ALTER TABLE INVENTORIES ADD PRIMARY KEY (ID);
ALTER TABLE COLORS ADD PRIMARY KEY (ID);
ALTER TABLE SETS ADD PRIMARY KEY (SET_NUM);
ALTER TABLE PARTS ADD PRIMARY KEY (PART_NUM);
ALTER TABLE THEMES ADD PRIMARY KEY (ID);
ALTER TABLE PART_CATEGORIES ADD PRIMARY KEY (ID);

-- setting foreign keys

ALTER TABLE INVENTORY_SETS ADD FOREIGN KEY (INVENTORY_ID) REFERENCES INVENTORIES (ID);
ALTER TABLE INVENTORY_SETS ADD FOREIGN KEY (SET_NUM) REFERENCES SETS (SET_NUM);

ALTER TABLE INVENTORY_PARTS ADD FOREIGN KEY (PART_NUM) REFERENCES PARTS (PART_NUM);
ALTER TABLE INVENTORY_PARTS ADD FOREIGN KEY (COLOR_ID) REFERENCES COLORS (ID);
ALTER TABLE INVENTORY_PARTS ADD FOREIGN KEY (INVENTORY_ID) REFERENCES INVENTORIES (ID);

ALTER TABLE INVENTORIES ADD FOREIGN KEY (SET_NUM) REFERENCES SETS (SET_NUM);

ALTER TABLE SETS ADD FOREIGN KEY (THEME_ID) REFERENCES THEMES (ID);

ALTER TABLE PARTS ADD FOREIGN KEY (PART_CAT_ID) REFERENCES PART_CATEGORIES (ID);

-- PART TWO ANALYSIS

-- Question 1 - Identify parts that appear in only one LEGO set. Note the quantity of the part does not matter.


-- Question 2 - For each LEGO set, calculate the number of unique parts it includes and the total number of parts (we're looking for a count of the parts, not quantity). Calculate the ratio of unique parts to total parts as a measure of 'uniqueness' for each set. Enrich your query with the set year and theme name.

-- join inventories and sets table
with inventory_sets as  
(
select 
    a.set_num as set_number,
    a.name,
    theme_id,
    num_parts,
    year,
    b.id as id1
from sets as a 
inner join inventories as b 
    on a.set_num = b.set_num
),

-- join inventory parts and parts table
parts_inventory as 
(
select a.part_num as parts,
    inventory_id as id2,
from parts as a
left join inventory_parts as b
    on a.part_num = b.part_num 
),

-- calculate unique lego pieces 
unique_parts_table as 
(
select distinct parts,
    count(set_number) as unique_parts,
    min(set_number) as set_number
from parts_inventory as a 
left join inventory_sets as b 
    on a.id2 = b.id1
group by parts
having unique_parts =1 

),

-- join unique table with the rest of the tables
main_table as 
(
select 
    a.name,
    set_number,
    a.year,
    num_parts,
    b.name as theme_name
from inventory_sets as a
inner join themes as b
    on a.theme_id = b.id
inner join parts_inventory as c
    on a.id1 = c.id2
group by all 

)

-- final clean up and calculate unique ratio
select distinct 
    name, 
    year,
    theme_name,
    count(unique_parts) as unique_parts,
    num_parts as total_parts,
    unique_parts/total_parts as unique_ratio
from main_table 
left join unique_parts_table
    on main_table.set_number = unique_parts_table.set_number
group by all;