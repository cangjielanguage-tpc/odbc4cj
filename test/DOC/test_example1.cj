// EXEC: cjc %import-path %L %l %f
// EXEC: ./main

import std.database.sql.*
import std.io.*
import std.time.*
import std.regex.*
import odbc4cj.*

main() {
    var driver = OdbcDriver()
    var database = driver.open("DATABASE=mysql;UID=root;PWD=123")
    var conn = database.connect()
    var prepareStatement = conn.prepareStatement("drop table if exists test")
    var rowCount = prepareStatement.update()
    println(rowCount.rowCount)
    prepareStatement = conn.prepareStatement("create table test(data int NOT NULL, datanull int)")
    rowCount = prepareStatement.update()
    println(rowCount.rowCount)
    prepareStatement = conn.prepareStatement("insert into test values(?,?)")
    prepareStatement.set<Int32>(0, 12345)
    prepareStatement.set<Option<Int32>>(1, Option<Int32>.None)
    // prepareStatement.setNull(1)
    rowCount = prepareStatement.update()
    println(rowCount.rowCount)
    prepareStatement = conn.prepareStatement("select * from test")
    var queryResult = prepareStatement.query()
    let a = queryResult.next()
    println(a)
    println(queryResult.columnInfos[0].typeName)
    println(queryResult.columnInfos[1].typeName)
    println(queryResult.get<Int32>(0))
    println(queryResult.getOrNull<Int32>(1))
    queryResult.close()
}
