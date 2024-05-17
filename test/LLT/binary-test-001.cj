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
        prepareStatement = conn.prepareStatement("create table test_llt(data BINARY(20) NOT NULL, datanull BINARY(20))")
        rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("insert into test_llt values(?,?)")
        rowCount = prepareStatement.update([SqlBinary([0,22]), SqlNullableBinary(None)])
        @Assert(1, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("select * from test_llt")
        var queryResult = prepareStatement.query()
        var arr: Array<SqlDbType> = [SqlBinary([0,11]), SqlNullableBinary(None)]
        queryResult.next(arr)
        @Assert("SqlBinary", queryResult.columnInfos[0].typeName)
        match (arr[0]) {
            case v: SqlBinary => @Assert(true, v.value[..2]==[0, 22])
            case _ => @Assert("abc", "123")
        }
        @Assert("SqlNullableBinary", queryResult.columnInfos[1].typeName)
        match (arr[1]) {
            case v: SqlNullableBinary => @Assert(None, v.value)
            case _ => @Assert("abc", "123")
        }
        queryResult.close()
    }
}
