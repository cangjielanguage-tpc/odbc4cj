// EXEC: cjc %import-path %L %l %f
// EXEC: ./main

package odbc
from std import database.sql.*, io.*, time.*, regex.*
from odbc4cj import odbc.*

main() {
    var driver = OdbcDriver()
    var database = driver.open("DATABASE=mysql;UID=root;PWD=123")
    var conn = database.connect()
    var prepareStatement = conn.prepareStatement("drop table if exists test")
    var rowCount = prepareStatement.update()
    prepareStatement = conn.prepareStatement("create table test(data int NOT NULL, datanull int)")
    rowCount = prepareStatement.update()
    prepareStatement = conn.prepareStatement("insert into test values(?,?)")
    rowCount = prepareStatement.update([SqlInteger(12345), SqlNullableInteger(None)])
    prepareStatement = conn.prepareStatement("select * from test")
    var queryResult = prepareStatement.query()
    var arr: Array<SqlDbType> = [SqlInteger(1), SqlNullableInteger(1)]
    queryResult.next(arr)
    match (arr[0]) {
        case v: SqlInteger => println(v.value)
        case _ => ()
    }
    match (arr[1]) {
        case v: SqlNullableInteger => println(v.value)
        case _ => ()
    }
}