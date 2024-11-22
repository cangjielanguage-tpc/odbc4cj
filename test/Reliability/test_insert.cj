//3rd_party_lib:odbc4cj/build/odbc4cj

import std.database.sql.* 
import std.io.*
import std.time.*
import std.regex.*
import std.math.*
import std.collection.*
import odbc4cj.*

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
                        var prepareStatement = conn.prepareStatement("drop table if exists test")
                        var rowCount = prepareStatement.update()
                        prepareStatement = conn.prepareStatement("create table test(data blob(5000) NOT NULL, datanull blob(20))")
                        rowCount = prepareStatement.update()
                        prepareStatement = conn.prepareStatement("insert into test values(?,?)")
                        var str = ByteArrayStream(20)
                        str.write([11, 22, 33, 44, 55, 66, 77, 88])
                        var reFlag = prepareStatement.update([SqlBlob(str), SqlNullableBlob(None)]).rowCount
                    if(reFlag==1){
                        result.append("success")
                    }else{
                        result.append("fail")
                    }
                } catch (e: Exception) {
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

public func testParseParameterMap():Int64 {

        var driver = OdbcDriver()
        var database = driver.open("DATABASE=mysql;UID=root;PWD=123")
        var conn = database.connect()
        var prepareStatement = conn.prepareStatement("drop table if exists test")
        var rowCount = prepareStatement.update()
        prepareStatement = conn.prepareStatement("create table test(data blob(5000) NOT NULL, datanull blob(20))")
        rowCount = prepareStatement.update()
        prepareStatement = conn.prepareStatement("insert into test values(?,?)")
        var str = ByteArrayStream(20)
        str.write([11, 22, 33, 44, 55, 66, 77, 88])
        var row = prepareStatement.update([SqlBlob(str), SqlNullableBlob(None)]).rowCount
        return row
}

