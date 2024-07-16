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
        prepareStatement = conn.prepareStatement("create table test(data VarBinary(20) NOT NULL, datanull VarBinary(20))")
        rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("insert into test values(?,?)")
        rowCount = prepareStatement.update([SqlVarBinary([11,22]), SqlNullableVarBinary(None)])
        @Assert(1, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("select * from test")
        var queryResult = prepareStatement.query()
        var arr: Array<SqlDbType> = [SqlVarBinary([11,22]), SqlNullableVarBinary(None)]
        queryResult.next(arr)
        @Assert("SqlVarBinary", queryResult.columnInfos[0].typeName)
        match (arr[0]) {
            case v: SqlVarBinary => @Assert(true, v.value[..2]==[11, 22])
            case _ => @Assert("abc", "123")
        }
        @Assert("SqlNullableVarBinary", queryResult.columnInfos[1].typeName)
        match (arr[1]) {
            case v: SqlNullableVarBinary => @Assert(None, v.value)
            case _ => @Assert("abc", "123")
        }
        queryResult.close()
    }
}
