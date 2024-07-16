//3rd_party_lib:odbc4cj/build/odbc4cj

import std.database.sql.* 
import std.io.*
import std.time.*
import std.regex.*
import odbc4cj.*

@Test
public class OdbcTest {
    init() {
    }
    @TestCase
    public func test001(): Unit {
        var driver = OdbcDriver()
        var database = driver.open("DATABASE=mysql;UID=root;PWD=123")
        var conn = database.connect()
        var prepareStatement = conn.prepareStatement("drop table if exists test")
        var rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("create table test(id int NOT NULL, data varchar(20) NOT NULL)")
        rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("insert into test values(?,?)")
        rowCount = prepareStatement.update([SqlInteger(1), SqlVarchar("abc")])
        @Assert(1, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("select * from test where id = ?")
        var queryResult = prepareStatement.query(SqlInteger(1))
        var arr: Array<SqlDbType> = [SqlInteger(3), SqlVarchar("1")]
        queryResult.next(arr)
        println(queryResult.columnInfos[0].typeName)
        @Assert("SqlInteger", queryResult.columnInfos[0].typeName)
        match (arr[0]) {
            case v: SqlInteger => @Assert(1, v.value)
            case _ => @Assert("abc", "123")
        }
        @Assert("SqlVarchar", queryResult.columnInfos[1].typeName)
        match (arr[1]) {
            case v: SqlVarchar => @Assert("abc", v.value)
            case _ => @Assert("abc", "123")
        }
        queryResult.close()
    }
}
