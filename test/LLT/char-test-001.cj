// EXEC: cjc %import-path %L %l %f
// EXEC: ./main

package odbc
from std import database.sql.*, io.*, time.*, regex.*
from odbc4cj import odbc.*
from std import unittest.*
from std import unittest.testmacro.*

main(): Int64 {
    let filterResultTest: OdbcTest = OdbcTest()

    filterResultTest.testChar()

    return 0
}

@Test
public class OdbcTest {
    @TestCase
    public func testChar(): Unit {
        var driver = OdbcDriver()
        var database = driver.open("DATABASE=mysql;UID=root;PWD=123")
        var conn = database.connect()
        var prepareStatement = conn.prepareStatement("drop table if exists test")
        var rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("create table test(data char(20) NOT NULL, datanull char(20))")
        rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("insert into test values(?,?)")
        rowCount = prepareStatement.update([SqlChar("abc"), SqlNullableChar(None)])
        @Assert(1, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("select * from test")
        var queryResult = prepareStatement.query()
        var arr: Array<SqlDbType> = queryResult.getSqlDbType()
        queryResult.next(arr)
        @Assert("SqlChar", queryResult.columnInfos[0].typeName)
        match (arr[0]) {
            case v: SqlChar => @Assert("abc", v.value)
            case _ => @Assert("abc", "123")
        }
        @Assert("SqlNullableChar", queryResult.columnInfos[1].typeName)
        match (arr[1]) {
            case v: SqlNullableChar => @Assert(None, v.value)
            case _ => @Assert("abc", "123")
        }
    }
}
