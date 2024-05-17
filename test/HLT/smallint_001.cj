//3rd_party_lib:odbc4cj/build/odbc4cj

from std import database.sql.*, io.*, time.*, regex.*, math.*
from odbc4cj import odbc.*

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
        prepareStatement = conn.prepareStatement("create table test(data SmallInt NOT NULL, datanull SmallInt)")
        rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("insert into test values(?,?)")
        rowCount = prepareStatement.update([SqlSmallInt(Int16.Max), SqlNullableSmallInt(None)])
        @Assert(1, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("select * from test")
        var queryResult = prepareStatement.query()
        var arr: Array<SqlDbType> = [SqlSmallInt(Int16.Max), SqlNullableSmallInt(None)]
        queryResult.next(arr)
        @Assert("SqlSmallInt", queryResult.columnInfos[0].typeName)
        match (arr[0]) {
            case v: SqlSmallInt => @Assert(Int16.Max, v.value)
            case _ => @Assert("abc", "123")
        }
        @Assert("SqlNullableSmallInt", queryResult.columnInfos[1].typeName)
        match (arr[1]) {
            case v: SqlNullableSmallInt => @Assert(None, v.value)
            case _ => @Assert("abc", "123")
        }
        queryResult.close()
    }
}
