// EXEC: cjc %import-path %L %l %f
// EXEC: ./main

package odbc
from std import database.sql.*, io.*, time.*, regex.*
from odbc4cj import odbc.*
from std import unittest.*
from std import unittest.testmacro.*

main(): Int64 {
    let filterResultTest: OdbcTest = OdbcTest()

    filterResultTest.test001()

    return 0
}

@Test
public class OdbcTest {
    @TestCase
    public func test001(): Unit {
        var driver = OdbcDriver()
        var database = driver.open("DATABASE=mysql;UID=root;PWD=123")
        var conn = database.connect()
        var prepareStatement = conn.prepareStatement("drop table if exists test_llt")
        var rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("create table test_llt(data double(5,2) NOT NULL, datanull double)")
        rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("insert into test_llt values(?,?)")
        rowCount = prepareStatement.update([SqlDouble(123.45), SqlNullableDouble(None)])
        @Assert(1, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("select * from test_llt")
        var queryResult = prepareStatement.query()
        var arr: Array<SqlDbType> = [SqlDouble(123.45), SqlNullableDouble(None)]
        queryResult.next(arr)
        @Assert("SqlDouble", queryResult.columnInfos[0].typeName)
        match (arr[0]) {
            case v: SqlDouble => @Assert(123.45, v.value)
            case _ => @Assert("abc", "123")
        }
        @Assert("SqlNullableDouble", queryResult.columnInfos[1].typeName)
        match (arr[1]) {
            case v: SqlNullableDouble => @Assert(None, v.value)
            case _ => @Assert("abc", "123")
        }
        queryResult.close()
    }
}
