//3rd_party_lib:odbc4cj/build/odbc4cj

import std.database.sql.* 
import std.io.*
import std.time.*
import std.regex.*
import std.math.*
import odbc4cj.*

@Test
public class bigint_001 {
    var conn: Connection
    var prepareStatement: Statement
    var rowCount: UpdateResult
    init(){
        var driver = OdbcDriver()
        var database = driver.open("DATABASE=mysql;UID=root;PWD=123")
        conn = database.connect()
        prepareStatement = conn.prepareStatement("drop table if exists test")
        rowCount = prepareStatement.update([])
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("create table test(data bigint NOT NULL, datanull bigint)")
        rowCount = prepareStatement.update([])
        @Assert(0, rowCount.rowCount)
    }

    @TestCase
    public func bigint_001(): Unit {
        prepareStatement = conn.prepareStatement("insert into test values(?,?)")
        var rowCount = prepareStatement.update([SqlBigInt(Int64.Max), SqlNullableBigInt(None)])
        @Assert(1, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("select * from test")
        var queryResult = prepareStatement.query([])
        var arr: Array<SqlDbType> = [SqlBigInt(0), SqlNullableBigInt(0)]
        queryResult.next(arr)
        @Assert("SqlBigInt", queryResult.columnInfos[0].typeName)
        match (arr[0]) {
            case v: SqlBigInt => @Assert(Int64.Max, v.value)
            case _ => @Assert("abc", "123")
        }
        @Assert("SqlNullableBigInt", queryResult.columnInfos[1].typeName)
        match (arr[1]) {
            case v: SqlNullableBigInt => @Assert(None, v.value)
            case _ => @Assert("abc", "123")
        }
        queryResult.close()
    }
}
