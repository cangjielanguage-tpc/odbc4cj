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
        prepareStatement = conn.prepareStatement("create table test(data varchar(20) NOT NULL, datanull varchar(20))")
        rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("insert into test values(?,?)")
        rowCount = prepareStatement.update([SqlVarchar("12345678"), SqlNullableVarchar(None)])
        println(rowCount.rowCount)
        @Assert(1, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("select * from test")
        var queryResult = prepareStatement.query()
        var arr: Array<SqlDbType> = [SqlVarchar("abc"), SqlNullableVarchar(None)]
        queryResult.next(arr)
        @Assert("SqlVarchar", queryResult.columnInfos[0].typeName)
        match (arr[0]) {
            case v: SqlVarchar => @Assert("12345678", v.value)
            case _ => @Assert("abc", "123")
        }
        @Assert("SqlNullableVarchar", queryResult.columnInfos[1].typeName)
        match (arr[1]) {
            case v: SqlNullableVarchar => @Assert(None, v.value)
            case _ => @Assert("abc", "123")
        }
    }
}
