#include<stdlib.h>
#include<stdbool.h>
#include<string.h>
#include "Dipendenze\include\libpq-fe.h"


PGconn *connessioneDB(const char *dbname,const char *user,char *password,char *hostaddr, const char *port){
    char conninfo[250];
    sprintf(conninfo, "dbname=%s user=%s password=%s hostaddr=%s port=%s",
            dbname, user, password, hostaddr, port);
    PGconn *conn = PQconnectdb(conninfo);
    if (PQstatus(conn) == CONNECTION_BAD)
    {
        printf("Connessione fallita con errore: %s\n",PQerrorMessage(conn));
        PQfinish(conn);
        exit(1);
    }
    printf("Connessione stabilita");
    return conn;
}

bool controllaRes(const PGconn *conn, PGresult *res){
    if (PQresultStatus(res) != PGRES_TUPLES_OK)
    {
        printf("Non e' stato restituito un risultato valido %s\n",PQerrorMessage(conn));
        PQclear(res);
        return 0;
    }
    return 1;
};

void printRes(const PGconn *conn, PGresult *r)
{
    if (controllaRes(conn, r))
    {
        int tuple = PQntuples(r);
        int campi = PQnfields(r);

        printf("\n");
        for (int i = 0; i < campi; ++i)
        {
            printf("%s\t\t",PQfname(r, i));
        }
        printf("\n");
        for (int i = 0; i < tuple; ++i)
        {
            for (int n = 0; n < campi; ++n)
            {
                printf("%s\t\t",PQgetvalue(r, i, n));
            }
            printf("\n");
        }

        printf("\n");
    }
    PQclear(r);
    r = 0;
}

void eseguiQuery(PGconn *conn, const char *query, int nParams, const char const* secondParametri[])
{
    PGresult *res;
    if (nParams < 1)
    {
        res = PQexec(conn, query);
    }else
    {
        res = PQexecParams(conn, query, nParams, NULL, secondParametri, NULL, NULL, 0);
    }
    printRes(conn, res);
}


int main()
{
    PGconn *conn = connessioneDB("Game_Stop", "postgres", "1234", "127.0.0.1", "5432");
    const char *menu = {"    \nMENU\n"
                        "# - Descrizione\n\n"
                        "# - Inserimento di un valore non valido comporta un nuovo inserimento da parte dell'utente (corretto)\n"
                        "0 - Per uscire\n"
                        "1 - Mostrare il numero di scontrini che un negozio con valutazione “Molto Buono” ha emesso \n"
                        "2 - Mostrare il numero di un certo tipo di prodotti creati da una determinata azienda:\n"
                        "3 - Mostrare la media dello stipendio ed età dei dipendenti che lavorano nei negozi con sede in una determinata città e media stipendio lavoratori piu di 1200:\n"
                        "4 - Dato una certa data, Indicare I numero dei prodotto che sono ancora protetti da assicurazione che un azienda deve prendersi cura.\n"
                        "5 - Fare una classifica dei magazzini che possiedono il maggior numero di un determinato prodotto e specificare in quale sede si trovano tali magazzini.\n"
                        "6 - Mostrare i negozi e i corrispettivi magazzini  che hanno un valore totale dei prodotti (valore totale prodotti nei negozi + valore totale prodotti nei magazzini)>1000. \n"
    };
    char *query[6];

    int n = 0;

    const char const* secondParametri[2];
    while (true)
    {
        printf("%s\n",menu);
        printf("Query desiderata : ");
        scanf("%d",&n);
        int scelta;
        int scelta2;
        int scelta5;
        bool controllo= 0;
 
        if (n == 0)
        {
            break;
        }
        else if (n < 0 || n > 6)
        {
            printf("\n");
            printf("Query non valida, riprova!!");
        }
        else
        {
            if (n == 1)
            { 
                query[n-1] = "Select N.Nome, count(*) as NumScontrini \
                From Negozio as N JOIN Scontrino as S on N.Nome = S.Negozio \
                Where N.Valutazione = $1::VARCHAR(20)  \
                Group by N.Nome \
                Having count(*) > 3  \
                Order by count(*); ";

                do{ 
                const char *menu1 = {"    \nMENU\n"
                        "Scelta valutazione al negozio\n"
                        "1 - Molto scarso\n"
                        "2 - Scarso\n"
                        "3 - Medio\n"
                        "4 - Buono\n"
                        "5 - Molto buono\n"}; 

                printf("%s",menu1);
                scanf("%d", &scelta);
                switch (scelta) {
                        case 0 : secondParametri[0]= "Molto scarso"; break;
                        case 1 : secondParametri[0]= "Scarso"; break;
                        case 2 : secondParametri[0]= "Medio"; break;
                        case 3 : secondParametri[0]= "Buono"; break;
                        case 4 : secondParametri[0]= "Molto buono"; break;
                        default : printf("Scelta non valida\n"), controllo = 1; break;
                        }
                  }while(controllo == 1);

                eseguiQuery(conn, query[n-1], 1, secondParametri);
            }
            else if (n == 2)
            { 
                 query[n-1]= "Select A.Nome,count(*) as NumProdotti   \
                From Prodotto as P JOIN Azienda as A on P.Azienda = A.Nome   \
                Where A.Nome= $1::VARCHAR(50) AND P.tipo_prodotto = $2::VARCHAR(10)   \
                Group by A.Nome   \
                ORDER BY count (*) DESC";
                
                do{ 
                    controllo = 0;
                    const char *menu2 = {"    \nMENU\n"
                        "Scegli un nome dell'azienda:\n"
                        "0 - AZ_1\n"
                        "1 - AZ_2\n"
                        "2 - AZ_3\n"
                        "3 - AZ_4\n"
                        "4 - AZ_5\n"
                        "5 - AZ_6\n"}; 
                printf("%s",menu2);
                scanf("%d", &scelta);
                switch (scelta) {
                        case 0 : secondParametri[0]= "AZ_1"; break;
                        case 1 : secondParametri[0]= "AZ_2"; break;
                        case 2 : secondParametri[0]= "AZ_3"; break;
                        case 3 : secondParametri[0]= "AZ_4"; break;
                        case 4 : secondParametri[0]= "AZ_5"; break;
                        case 5 : secondParametri[0]= "AZ_6"; break;
                        default : printf("Scelta non valida\n"), controllo = 1; break;
                        }

                    const char *menu21 = {"    \nMENU\n"
                        "Scegli il tipo di prodotto: \n"
                        "0 - Gioco\n"
                        "1 - Console\n"}; 
                printf("%s",menu21);
                scanf("%d", &scelta);
                switch (scelta) {
                        case 0 : secondParametri[1]= "Gioco"; break;
                        case 1 : secondParametri[1]= "Console"; break;
                        default : printf("Scelta non valida\n"), controllo = 1; break;
                        }
                    }while(controllo == 1);
            
                eseguiQuery(conn, query[n-1], 2,secondParametri);
            }
            else if (n == 3)
           {   
                query[n-1]= "Select N.Nome, cast(AVG(L.Stipendio) as int) AS StipendioMedio, cast(AVG(L.eta) as int) as EtaMedia     \
                From Negozio as N join Lavoratore as L on N.Nome = L.Negozio    \
                Where N.Sede IN (Select N.Sede  \
                    From Sede as S join Negozio as N on S.Codice = N.Sede   \
                    Where S.Citta = $1::VARCHAR(30)) \
                Group by N.Nome \
                Having AVG(L.Stipendio) > 1200 \
                Order by AVG( L.Stipendio) DESC; ";
                 do{ 
                    controllo = 0;
                    const char *menu3 = {"    \nMENU\n"
                        "Scegli una citta: \n"
                        "0 - Roma\n"
                        "1 - Milano\n"
                        "2 - Venezia\n"
                        "3 - Padova\n"
                        "4 - Cremona\n"
                        "5 - Napoli\n"}; 
                printf("%s",menu3);
                scanf("%d", &scelta);
                switch (scelta) {
                        case 0 : secondParametri[0]= "Roma"; break;
                        case 1 : secondParametri[0]= "Milano"; break;
                        case 2 : secondParametri[0]= "Venezia"; break;
                        case 3 : secondParametri[0]= "Padova"; break;
                        case 4 : secondParametri[0]= "Cremona"; break;
                        case 5 : secondParametri[0]= "Napoli"; break;
                        default : printf("Scelta non valida\n"), controllo = 1; break;
                        }
                    }while(controllo == 1);
                eseguiQuery(conn, query[n-1], 1, secondParametri);
            }
            else if (n == 4){
                query[n-1]= "Select P.Azienda, count(*) as NumeroProdottiAssicurati   \
                            From Prodotto as P join Scontrino as S ON P.Nome = S.Prodotto   \
                            Where S.Data_Fine_Assicurazione > '2024-02-02'   \
                            GROUP BY P.Azienda   \
                            Order by count(*) DESC ;"   ;
                eseguiQuery(conn, query[n-1], 0, NULL);
            }
            else if (n == 5)
            {                 
                query[n-1] = "Select D.Magazzino, D.numero,M.Sede   \
                                From Deposito as D join Magazzino as M on D.Magazzino = M.Nome   \
                                Where D.Prodotto = $1::VARCHAR(50)   ";
                do{ 
                    controllo = 0;
                    const char *menu5 = {"    \nMENU\n"
                        "Scegli un prodotto tra quelli elencati:\n"
                        "0 - Batman\n"
                        "1 - Baldurs Gate 3\n"
                        "2 - DeadFire\n"
                        "3 - Divinity Original Sin\n"
                        "4 - PS5\n"
                        "5 - XBOX ONE\n"}; 
                printf("%s",menu5);
                scanf("%d", &scelta5);
                switch (scelta5) {
                        case 0 : secondParametri[0]= "Batman"; break;
                        case 1 : secondParametri[0]= "Baldurs Gate 3"; break;
                        case 2 : secondParametri[0]= "DeadFire"; break;
                        case 3 : secondParametri[0]= "Divinity Original Sin"; break;
                        case 4 : secondParametri[0]= "PS5"; break;
                        case 5 : secondParametri[0]= "XBOX ONE"; break;
                        default : printf("Scelta non valida\n"), controllo = 1; break;
                        }
    
                    }while(controllo == 1);
                eseguiQuery(conn, query[n-1], 1,secondParametri);
            }
            else if(n == 6){
                query[n-1]="select DI.negozio,sum(DI.numero) as Valore_Prodotti_Negozio, magazzino, sum(D.numero) as Valore_Prodotti_Magazzino, sum(DI.numero)+sum(D.numero) as Valore_Prodotti_Totale    \
                            from deposito as D,disponibilita_immediata as DI,Magazzino as M   \
                            where DI.Negozio=M.Negozio and M.Nome=D.Magazzino   \
                            group by DI.negozio,magazzino   \
                            having sum(DI.numero)+sum(D.numero)>1000;" ;    

                 eseguiQuery(conn, query[n-1], 0, NULL);
            }
            printf("\n");
        }
    }
    PQfinish(conn);

    return 0;
}