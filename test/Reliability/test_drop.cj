//3rd_party_lib:odbc4cj/build/odbc4cj

from std import database.sql.*, io.*, time.*, regex.*, math.*
from std import collection.*
from odbc4cj import odbc.*
//threadCount: 5,10,20,50,100,200,500
//loopCount:100,200,500,800,1000
main() {
    let threadCount = 100
    let loopCount = 10000
    let futures = ArrayList<Future<ArrayList<String>>>()
    let start = DateTime.now()
    for (_ in 0..threadCount) {
        let driver = OdbcDriver()
        let database = driver.open("DATABASE=mysql;UID=root;PWD=123")
        let conn = database.connect()
        let thread :Future<ArrayList<String>>= spawn {
            var result=ArrayList<String>()
            for (_ in 0..loopCount) {
                try {
                    conn.prepareStatement("create table testtable(data blob(5000) NOT NULL, datanull blob(20))")
                    var prepareStatement = conn.prepareStatement("drop table if exists testtable")
                    var row = prepareStatement.update().rowCount
                    if(row==0){
                        result.append("success")
                    }else{
                        result.append("fail")
                    }
                } catch (e: Exception) {
                    println(e.toString())
                    result.append("fail")
                    continue
                    // break
                    // Process.atexit({()=>println("got err ${e.message}")})
                    // Process.exit()
                }
            }
            conn.close()
            return result
        }
        futures.append(thread)
    }

    for (f in futures) {
        f.get()
    }
    let end = Duration.since(start).toSeconds()
    var count_fail=0
    for (f in futures){
        var temp_re=f.get()
        for (j in temp_re){
            if(j=="fail"){
                count_fail+=1
            }
        }
    }
    println("test_upload_parseParameterMap_MB10_TotalTime:${end}")
    println("test_upload_parseParameterMap_MB10_${threadCount}*${loopCount} TPS: ${Int64((threadCount*loopCount)/end)}")
    println("test_upload_parseParameterMap_MB10_${threadCount}*${loopCount} FailRate: ${count_fail/(threadCount*loopCount)*100} %")
}



