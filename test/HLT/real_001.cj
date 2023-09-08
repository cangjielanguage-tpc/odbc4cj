//3rd_party_lib:odbc4cj/build/odbc4cj

from std import database.sql.*, io.*, time.*, regex.*
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
        prepareStatement = conn.prepareStatement("create table test(data float(5,2) NOT NULL, datanull float)")
        rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("insert into test values(?,?)")
        rowCount = prepareStatement.update([SqlReal(123.45), SqlNullableReal(None)])
        @Assert(1, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("select * from test")
        var queryResult = prepareStatement.query()
        var arr: Array<SqlDbType> = [SqlReal(123.45), SqlNullableReal(None)]
        queryResult.next(arr)
        @Assert("SqlReal", queryResult.columnInfos[0].typeName)
        match (arr[0]) {
            case v: SqlReal => @Assert(123.45, v.value)
            case _ => @Assert("abc", "123")
        }
        @Assert("SqlNullableReal", queryResult.columnInfos[1].typeName)
        match (arr[1]) {
            case v: SqlNullableReal => @Assert(None, v.value)
            case _ => @Assert("abc", "123")
        }
    }
}
